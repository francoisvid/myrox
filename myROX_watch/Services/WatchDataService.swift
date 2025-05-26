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
        if activeWorkout != nil {
            print("Un workout est déjà actif, on ne crée pas de nouvelle session")
            return
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
            
            // Créer d'abord le workout
            DispatchQueue.main.async {
                self.activeWorkout = WatchWorkout(
                    templateId: template.id,
                    templateName: template.name,
                    startedAt: Date(),
                    exercises: template.exercises.map { WatchExercise(name: $0) }
                )
                print("Workout créé avec \(template.exercises.count) exercices")
            }
            
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
            "exercises": workout.exercises.map { ["name": $0.name, "duration": $0.duration] }
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
            
            if let templatesData = message["templates"] as? [[String: Any]] {
                self.templates = templatesData.compactMap { data in
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let name = data["name"] as? String,
                          let exercises = data["exercises"] as? [String] else {
                        return nil
                    }
                    return WatchTemplate(id: id, name: name, exercises: exercises)
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
