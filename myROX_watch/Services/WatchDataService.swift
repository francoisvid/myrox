import Foundation
import WatchConnectivity
import HealthKit

class WatchDataService: NSObject, ObservableObject {
    static let shared = WatchDataService()
    
    @Published var workoutCount: Int = 0
    @Published var templates: [WatchTemplate] = []
    @Published var activeWorkout: WatchWorkout?
    @Published var isPhoneReachable = false
    @Published var goals: [String: TimeInterval] = [:]
    @Published var personalBests: [WatchPersonalBest] = []
    
    private var session: WCSession
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    override init() {
        self.session = WCSession.default
        super.init()
        
        if let savedGoals = UserDefaults.standard.object(forKey: "exerciseGoals") as? [String: TimeInterval] {
            self.goals = savedGoals
        }
        
        if let savedPBData = UserDefaults.standard.data(forKey: "personalBests"),
           let savedPBs = try? JSONDecoder().decode([WatchPersonalBest].self, from: savedPBData) {
            self.personalBests = savedPBs
        }
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        
        requestHealthKitAuthorization()
    }
    
    // MARK: - Communication with iPhone
    
    func requestTemplates() {
        guard session.isReachable else { return }
        
        let message = ["action": "requestTemplates"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur demande templates: \(error)")
        }
    }
    
    func requestWorkoutCount() {
        guard session.isReachable else { return }
        
        let message = ["action": "requestWorkoutCount"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur demande count: \(error)")
        }
    }
    
    func requestGoals() {
        guard session.isReachable else { return }
        
        let message = ["action": "requestGoals"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur demande goals: \(error)")
        }
    }
    
    func requestPersonalBests() {
        guard session.isReachable else { return }
        
        let message = ["action": "requestPersonalBests"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur demande personal bests: \(error)")
        }
    }
    
    func sendCompletedWorkout(_ workout: WatchWorkout) {
        print("Envoi du workout complété - Durée totale: \(workout.totalDuration)")
        
        guard session.isReachable else {
            // Sauvegarder localement si iPhone non accessible
            saveWorkoutLocally(workout)
            return
        }
        
        let workoutData: [String: Any] = [
            "templateId": workout.templateId?.uuidString ?? "",
            "templateName": workout.templateName,
            "startedAt": workout.startedAt.timeIntervalSince1970,
            "totalDuration": workout.totalDuration,
            "totalDistance": workout.totalDistance,
            "exercises": workout.exercises.map { exercise in
                [
                    "name": exercise.name,
                    "duration": exercise.duration,
                    "distance": exercise.distance,
                    "repetitions": exercise.repetitions,
                    "round": exercise.round,
                    "order": exercise.order,
                    "heartRate": exercise.heartRatePoints.map { point in
                        ["value": point.value, "timestamp": point.timestamp.timeIntervalSince1970]
                    }
                ]
            }
        ]
        
        let message: [String: Any] = [
            "action": "workoutCompleted",
            "workout": workoutData
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur envoi workout: \(error)")
            self.saveWorkoutLocally(workout)
        }
    }
    
    // MARK: - HealthKit
    
    private func requestHealthKitAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func startWorkoutSession(for template: WatchTemplate) {
        print("Démarrage de la session de workout pour le template: \(template.name)")
        
        // Vérifier si un workout est déjà actif
        if let existingWorkout = activeWorkout {
            print("Un workout est déjà actif: \(existingWorkout.templateName)")
            
            // Si c'est le même template, ne pas créer de nouveau workout mais permettre la navigation
            if existingWorkout.templateName == template.name {
                print("Même template déjà actif, autorisation de continuer")
                return
            }
            
            // Si c'est un template différent, remplacer le workout actuel
            print("Template différent, remplacement du workout actuel")
            endWorkoutSession()
        }
        
        // 🔧 CRÉER LE WORKOUT IMMÉDIATEMENT (synchrone) pour que la navigation fonctionne
        var exercises: [WatchExercise] = []
        let rounds = template.rounds
        let templateExercises = template.templateExercises
        
        for round in 1...rounds {
            let roundExercises = templateExercises.map { templateExercise in
                WatchExercise(
                    name: templateExercise.name,
                    round: round,
                    order: templateExercise.order,
                    targetDistance: templateExercise.targetDistance,
                    targetRepetitions: templateExercise.targetRepetitions,
                    targetDuration: templateExercise.targetDuration
                )
            }
            exercises.append(contentsOf: roundExercises)
        }
        
        // Créer le workout IMMÉDIATEMENT (synchrone sur le thread principal)
        self.activeWorkout = WatchWorkout(
            templateId: template.id,
            templateName: template.name,
            startedAt: Date(),
            exercises: exercises
        )
        print("Workout créé avec \(exercises.count) exercices répartis sur \(rounds) rounds")
        for exercise in exercises {
            let params = [
                exercise.targetDistance.map { "\($0)m" },
                exercise.targetRepetitions.map { "\($0) reps" }
            ].compactMap { $0 }.joined(separator: ", ")
            print("Round \(exercise.round) - \(exercise.name) \(params)")
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = workoutSession?.associatedWorkoutBuilder()
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutSession?.delegate = self
            builder?.delegate = self
            
            // Démarrer la session HealthKit
            workoutSession?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { [weak self] success, error in
                guard let self = self else { return }
                if success {
                    print("Collection de données HealthKit démarrée avec succès")
                } else if let error = error {
                    print("Échec du démarrage de la collection HealthKit: \(error)")
                }
            }
        } catch {
            print("Échec de la création de la session de workout: \(error)")
        }
    }
    
    func endWorkoutSession() {
        print("Début de la fin de session")
        guard let session = workoutSession else {
            print("Pas de session active")
            DispatchQueue.main.async {
                if let workout = self.activeWorkout {
                    print("Envoi du workout avant nettoyage - Durée: \(workout.totalDuration)")
                    self.sendCompletedWorkout(workout)
                }
                self.activeWorkout = nil
                self.workoutSession = nil
                self.builder = nil
            }
            return
        }
        
        // Vérifier l'état actuel de la session
        if session.state == .running {
            print("Arrêt de la session en cours")
            session.end()
            
            builder?.endCollection(withEnd: Date()) { [weak self] success, error in
                guard let self = self else { return }
                if success {
                    print("Collection terminée avec succès")
                    self.builder?.finishWorkout { [weak self] workout, error in
                        guard let self = self else { return }
                        if let workout = self.activeWorkout {
                            print("Envoi du workout complété - Durée: \(workout.totalDuration)")
                            self.sendCompletedWorkout(workout)
                        }
                        
                        DispatchQueue.main.async {
                            print("Nettoyage des ressources")
                            self.activeWorkout = nil
                            self.workoutSession = nil
                            self.builder = nil
                        }
                    }
                } else if let error = error {
                    print("Échec de la fin de collection: \(error)")
                    DispatchQueue.main.async {
                        if let workout = self.activeWorkout {
                            print("Envoi du workout malgré l'erreur - Durée: \(workout.totalDuration)")
                            self.sendCompletedWorkout(workout)
                        }
                        self.activeWorkout = nil
                        self.workoutSession = nil
                        self.builder = nil
                    }
                }
            }
        } else {
            print("Session déjà terminée, nettoyage")
            // Si la session n'est pas en cours d'exécution, nettoyer simplement
            DispatchQueue.main.async {
                if let workout = self.activeWorkout {
                    print("Envoi du workout avant nettoyage - Durée: \(workout.totalDuration)")
                    self.sendCompletedWorkout(workout)
                }
                self.activeWorkout = nil
                self.workoutSession = nil
                self.builder = nil
            }
        }
    }
    
    // MARK: - Local Storage
    
    private func saveWorkoutLocally(_ workout: WatchWorkout) {
        print("Sauvegarde locale du workout - Durée totale: \(workout.totalDuration)")
        // Sauvegarder en UserDefaults pour synchroniser plus tard
        var savedWorkouts = UserDefaults.standard.object(forKey: "pendingWorkouts") as? [[String: Any]] ?? []
        
        let workoutData: [String: Any] = [
            "id": workout.id.uuidString,
            "templateName": workout.templateName,
            "startedAt": workout.startedAt.timeIntervalSince1970,
            "totalDuration": workout.totalDuration,
            "exercises": workout.exercises.map { 
                [
                    "name": $0.name, 
                    "duration": $0.duration,
                    "round": $0.round,
                    "order": $0.order,
                    "distance": $0.distance,
                    "repetitions": $0.repetitions
                ] 
            }
        ]
        
        savedWorkouts.append(workoutData)
        UserDefaults.standard.set(savedWorkouts, forKey: "pendingWorkouts")
    }
    
    func syncPendingWorkouts() {
        guard session.isReachable else { return }
        
        if let pendingWorkouts = UserDefaults.standard.object(forKey: "pendingWorkouts") as? [[String: Any]] {
            for workoutData in pendingWorkouts {
                let message: [String: Any] = [
                    "action": "workoutCompleted",
                    "workout": workoutData
                ]
                session.sendMessage(message, replyHandler: nil)
            }
            
            UserDefaults.standard.removeObject(forKey: "pendingWorkouts")
        }
    }
    

}

// MARK: - WCSessionDelegate

extension WatchDataService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
        }
        
        if activationState == .activated {
            requestTemplates()
            requestWorkoutCount()
            requestGoals()
            requestPersonalBests()
            syncPendingWorkouts()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
        }
        
        if session.isReachable {
            requestTemplates()
            requestWorkoutCount()
            requestGoals()
            requestPersonalBests()
            syncPendingWorkouts()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let count = message["workoutCount"] as? Int {
                self.workoutCount = count
            }
            
            if let goalsData = message["goals"] as? [[String: Any]] {
                var newGoals: [String: TimeInterval] = [:]
                for goalData in goalsData {
                    if let exerciseName = goalData["exerciseName"] as? String,
                       let targetTime = goalData["targetTime"] as? TimeInterval {
                        newGoals[exerciseName] = targetTime
                    }
                }
                self.goals = newGoals
                
                // Sauvegarder localement
                UserDefaults.standard.set(newGoals, forKey: "exerciseGoals")
            }
            
            if let personalBestsData = message["personalBests"] as? [[String: Any]] {
                let newPersonalBests = personalBestsData.compactMap { pbData -> WatchPersonalBest? in
                    guard let exerciseType = pbData["exerciseType"] as? String,
                          let value = pbData["value"] as? Double,
                          let achievedAtTimestamp = pbData["achievedAt"] as? TimeInterval else {
                        return nil
                    }
                    
                    let achievedAt = Date(timeIntervalSince1970: achievedAtTimestamp)
                    return WatchPersonalBest(exerciseType: exerciseType, value: value, achievedAt: achievedAt)
                }
                
                self.personalBests = newPersonalBests
                
                // Sauvegarder localement
                if let encoded = try? JSONEncoder().encode(newPersonalBests) {
                    UserDefaults.standard.set(encoded, forKey: "personalBests")
                }
            }
            
            if let templatesData = message["templates"] as? [[String: Any]] {
                self.templates = templatesData.compactMap { data in
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let name = data["name"] as? String,
                          let exercises = data["exercises"] as? [String],
                          let rounds = data["rounds"] as? Int else {
                        return nil
                    }
                    
                    // Traiter les nouvelles données d'exercices avec paramètres
                    var exercisesData: [WatchTemplateExercise] = []
                    if let exercisesDataArray = data["exercisesData"] as? [[String: Any]] {
                        exercisesData = exercisesDataArray.compactMap { exerciseData in
                            guard let exerciseName = exerciseData["name"] as? String,
                                  let order = exerciseData["order"] as? Int else {
                                return nil
                            }
                            
                            let targetDistance = exerciseData["targetDistance"] as? Double
                            let targetRepetitions = exerciseData["targetRepetitions"] as? Int
                            
                            return WatchTemplateExercise(
                                name: exerciseName,
                                order: order,
                                targetDistance: targetDistance,
                                targetRepetitions: targetRepetitions
                            )
                        }
                    }
                    
                    return WatchTemplate(
                        id: id, 
                        name: name, 
                        exercises: exercises, 
                        rounds: rounds, 
                        exercisesData: exercisesData
                    )
                }
            }
            
            if let action = message["action"] as? String {
                switch action {
                case "workoutDeleted":
                    if let workoutIdString = message["workoutId"] as? String,
                       let workoutId = UUID(uuidString: workoutIdString) {
                        // Supprimer le workout des workouts en attente
                        if var pendingWorkouts = UserDefaults.standard.object(forKey: "pendingWorkouts") as? [[String: Any]] {
                            pendingWorkouts.removeAll { workoutData in
                                if let idString = workoutData["id"] as? String,
                                   let id = UUID(uuidString: idString) {
                                    return id == workoutId
                                }
                                return false
                            }
                            UserDefaults.standard.set(pendingWorkouts, forKey: "pendingWorkouts")
                        }
                    }
                case "templateDeleted":
                    if let templateIdString = message["templateId"] as? String,
                       let templateId = UUID(uuidString: templateIdString) {
                        // Supprimer le template de la liste
                        self.templates.removeAll { $0.id == templateId }
                    }

                default:
                    break
                }
            }
            
            if let workoutData = message["activeWorkout"] as? [String: Any] {
                // Synchroniser un workout actif depuis iPhone
                // (optionnel pour une v2)
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate & HKLiveWorkoutBuilderDelegate

extension WatchDataService: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                       didChangeTo toState: HKWorkoutSessionState,
                       from fromState: HKWorkoutSessionState,
                       date: Date) {
        // Gérer les changements d'état
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                       didFailWithError error: Error) {
        print("Workout session error: \(error)")
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            if type == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                // Récupérer les données de fréquence cardiaque
                if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
                   let statistics = workoutBuilder.statistics(for: heartRateType) {
                    let heartRate = Int(statistics.mostRecentQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0)
                    
                    // Ajouter au dernier exercice actif
                    if let currentExerciseIndex = activeWorkout?.exercises.firstIndex(where: { !$0.isCompleted }) {
                        activeWorkout?.exercises[currentExerciseIndex].heartRatePoints.append(
                            (value: heartRate, timestamp: Date())
                        )
                    }
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Gérer les événements
    }
}
