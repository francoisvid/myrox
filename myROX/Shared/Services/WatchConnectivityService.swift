import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    // MARK: - Published Properties
    @Published var isReachable = false
    
    // MARK: - Private Properties
    private var session: WCSession
    private let modelContext: ModelContext
    
    // MARK: - Constants
    private enum SyncDelays {
        static let personalBestSync: UInt64 = 2_000_000_000 // 2 secondes
        static let notificationDelay: UInt64 = 1_000_000_000 // 1 seconde
    }
    
    override init() {
        self.session = WCSession.default
        self.modelContext = ModelContainer.shared.mainContext
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Public Send Methods
    
    func sendWorkoutCount() {
        guard session.isReachable else { return }
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.completedAt != nil }
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            let message = ["workoutCount": workouts.count]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("❌ Erreur envoi workout count: \(error)")
            }
        } catch {
            print("❌ Erreur fetch workouts: \(error)")
        }
    }
    
    func sendTemplates() {
        guard session.isReachable else { return }
        
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        
        do {
            let templates = try modelContext.fetch(descriptor)
            let templatesData = buildTemplatesData(from: templates)
            let message = ["templates": templatesData]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("❌ Erreur envoi templates: \(error)")
            }
        } catch {
            print("❌ Erreur fetch templates: \(error)")
        }
    }
    
    func sendActiveWorkout(_ workout: Workout) {
        guard session.isReachable else { return }
        
        let workoutData = buildActiveWorkoutData(from: workout)
        let message = ["activeWorkout": workoutData]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("❌ Erreur envoi workout actif: \(error)")
        }
    }
    
    func sendGoals() {
        guard session.isReachable else { return }
        
        let descriptor = FetchDescriptor<ExerciseGoal>()
        
        do {
            let goals = try modelContext.fetch(descriptor)
            let goalsData = goals.map { goal in
                [
                    "exerciseName": goal.exerciseName,
                    "targetTime": goal.targetTime
                ]
            }
            
            let message = ["goals": goalsData]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("❌ Erreur envoi goals: \(error)")
            }
        } catch {
            print("❌ Erreur fetch goals: \(error)")
        }
    }
    
    func sendPersonalBests() {
        guard session.isReachable else { return }
        
        let descriptor = FetchDescriptor<PersonalBest>()
        
        do {
            let personalBests = try modelContext.fetch(descriptor)
            let personalBestsData = personalBests.map { pb in
                [
                    "exerciseType": pb.exerciseType,
                    "value": pb.value,
                    "achievedAt": pb.achievedAt.timeIntervalSince1970
                ]
            }
            
            let message = ["personalBests": personalBestsData]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("❌ Erreur envoi personal bests: \(error)")
            }
        } catch {
            print("❌ Erreur fetch personal bests: \(error)")
        }
    }
    
    // MARK: - Public Delete Methods
    
    func sendWorkoutDeleted(_ workoutId: UUID) {
        guard session.isReachable else { return }
        
        let message = [
            "action": "workoutDeleted",
            "workoutId": workoutId.uuidString
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("❌ Erreur envoi suppression workout: \(error)")
        }
    }
    
    func sendTemplateDeleted(_ templateId: UUID) {
        guard session.isReachable else { return }
        
        let message = [
            "action": "templateDeleted",
            "templateId": templateId.uuidString
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("❌ Erreur envoi suppression template: \(error)")
        }
    }
    
    // MARK: - Private Data Building Methods
    
    private func buildTemplatesData(from templates: [WorkoutTemplate]) -> [[String: Any]] {
        return templates.map { template in
            // Construire les données d'exercices avec paramètres
            let exercisesData = template.exercises.sorted(by: { $0.order < $1.order }).map { templateExercise in
                var exerciseData: [String: Any] = [
                    "name": templateExercise.exerciseName,
                    "order": templateExercise.order
                ]
                
                if let distance = templateExercise.targetDistance, distance > 0 {
                    exerciseData["targetDistance"] = distance
                }
                
                if let reps = templateExercise.targetRepetitions, reps > 0 {
                    exerciseData["targetRepetitions"] = reps
                }
                
                return exerciseData
            }
            
            // Créer aussi la liste des noms pour compatibilité Watch
            let exerciseNames = template.exercises.sorted(by: { $0.order < $1.order }).map { $0.exerciseName }
            
            return [
                "id": template.id.uuidString,
                "name": template.name,
                "exercisesData": exercisesData,
                "exercises": exerciseNames, // Compatibilité avec l'ancien format Watch
                "rounds": template.rounds
            ]
        }
    }
    
    private func buildActiveWorkoutData(from workout: Workout) -> [String: Any] {
        return [
            "id": workout.id.uuidString,
            "startedAt": workout.startedAt.timeIntervalSince1970,
            "exercises": workout.performances.map { exercise in
                [
                    "name": exercise.exerciseName,
                    "duration": exercise.duration,
                    "completed": exercise.completedAt != nil
                ]
            }
        ]
    }
    
    // MARK: - Workout Completion Handling
    
    func handleWorkoutCompleted(_ workoutData: [String: Any]) {
        print("🏋️ Traitement d'un workout complété depuis la Watch")
        
        // Créer le workout depuis les données Watch
        let workout = createWorkoutFromWatchData(workoutData)
        
        // Sauvegarder localement
        saveWorkoutLocally(workout)
        
        // Synchroniser avec l'API et envoyer la notification
        Task {
            await processWorkoutCompletion(workout)
        }
    }
    
    private func createWorkoutFromWatchData(_ workoutData: [String: Any]) -> Workout {
        let workout = Workout()
        
        // Récupérer les métadonnées du template
        if let templateIdString = workoutData["templateId"] as? String,
           !templateIdString.isEmpty,
           let templateId = UUID(uuidString: templateIdString) {
            workout.templateID = templateId
        }
        
        if let templateName = workoutData["templateName"] as? String {
            workout.templateName = templateName
        }
        
        // Créer les exercices depuis les données Watch
        if let exercises = workoutData["exercises"] as? [[String: Any]] {
            for exerciseData in exercises {
                let exercise = createWorkoutExercise(from: exerciseData)
                workout.performances.append(exercise)
            }
        }
        
        // Définir les métadonnées du workout
        workout.completedAt = Date()
        workout.totalDuration = workoutData["totalDuration"] as? TimeInterval ?? 0
        workout.totalDistance = workoutData["totalDistance"] as? Double ?? 0
        
        // Récupérer la vraie heure de début si disponible
        if let startedAtTimestamp = workoutData["startedAt"] as? TimeInterval {
            workout.startedAt = Date(timeIntervalSince1970: startedAtTimestamp)
        }
        
        return workout
    }
    
    private func createWorkoutExercise(from exerciseData: [String: Any]) -> WorkoutExercise {
        let exercise = WorkoutExercise(
            exerciseName: exerciseData["name"] as? String ?? "",
            round: exerciseData["round"] as? Int ?? 1,
            order: exerciseData["order"] as? Int ?? 0
        )
        
        exercise.duration = exerciseData["duration"] as? TimeInterval ?? 0
        exercise.distance = exerciseData["distance"] as? Double ?? 0
        exercise.repetitions = exerciseData["repetitions"] as? Int ?? 0
        exercise.completedAt = Date() // Marquer comme complété
        
        // Ajouter les données de fréquence cardiaque si disponibles
        if let heartRateData = exerciseData["heartRate"] as? [[String: Any]] {
            addHeartRateData(to: exercise, from: heartRateData)
        }
        
        return exercise
    }
    
    private func addHeartRateData(to exercise: WorkoutExercise, from heartRateData: [[String: Any]]) {
        for hrPoint in heartRateData {
            if let value = hrPoint["value"] as? Int,
               let timestamp = hrPoint["timestamp"] as? TimeInterval {
                let point = HeartRatePoint(
                    value: value,
                    timestamp: Date(timeIntervalSince1970: timestamp)
                )
                exercise.heartRatePoints.append(point)
            }
        }
        
        // Calculer les moyennes
        let values = exercise.heartRatePoints.map { $0.value }
        exercise.averageHeartRate = values.isEmpty ? 0 : values.reduce(0, +) / values.count
        exercise.maxHeartRate = values.max() ?? 0
    }
    
    private func saveWorkoutLocally(_ workout: Workout) {
        modelContext.insert(workout)
        
        do {
            try modelContext.save()
            print("✅ Workout Watch sauvé localement avec ID: \(workout.id)")
        } catch {
            print("❌ Erreur sauvegarde locale workout Watch: \(error)")
        }
    }
    
    // MARK: - Async Processing
    
    private func processWorkoutCompletion(_ workout: Workout) async {
        do {
            // 1. Synchroniser le workout avec l'API
            try await syncWorkoutWithAPI(workout)
            
            // 2. Synchroniser les Personal Bests mis à jour
            await syncPersonalBestsAfterWorkout()
            
            // 3. Envoyer la notification après synchronisation réussie
            await sendWorkoutCompletionNotification(for: workout)
            
        } catch {
            print("⚠️ Erreur synchronisation API workout Watch: \(error)")
            // Envoyer la notification même en cas d'erreur de sync
            await sendWorkoutCompletionNotification(for: workout, fallback: true)
        }
        
        // 4. Notifier l'app
        notifyAppOfWorkoutCompletion(workout)
    }
    
    private func syncWorkoutWithAPI(_ workout: Workout) async throws {
        let workoutRepository = WorkoutRepository(modelContext: modelContext)
        try await workoutRepository.syncCompletedWorkout(workout)
        print("✅ Workout Watch synchronisé avec l'API avec ID: \(workout.id)")
    }
    
    @MainActor
    private func syncPersonalBestsAfterWorkout() async {
        print("🔄 Synchronisation des Personal Bests après workout Watch...")
        
        // Attendre un court délai pour laisser l'API traiter les nouveaux records
        try? await Task.sleep(nanoseconds: SyncDelays.personalBestSync)
        
        let personalBestRepository = PersonalBestRepository(modelContext: modelContext)
        
        do {
            try await personalBestRepository.syncPersonalBestsWithCache()
            print("✅ Personal Bests synchronisés depuis l'API")
            
            // Envoyer les nouveaux Personal Bests à la Watch
            sendPersonalBests()
            print("📤 Nouveaux Personal Bests envoyés à la Watch")
            
        } catch {
            print("⚠️ Erreur synchronisation Personal Bests: \(error)")
        }
    }
    
    private func sendWorkoutCompletionNotification(for workout: Workout, fallback: Bool = false) async {
        await MainActor.run {
            Task {
                let mode = fallback ? "(fallback)" : ""
                print("🏋️ Séance terminée depuis la Watch - Envoi de notification \(mode)")
                print("🆔 Workout iPhone ID: \(workout.id) (utilisé pour la notification)")
                
                // Attendre un court délai pour s'assurer que tout est bien synchronisé
                try? await Task.sleep(nanoseconds: SyncDelays.notificationDelay)
                
                // Notification spécifique pour les séances Watch avec l'ID iPhone
                await NotificationService.shared.scheduleWorkoutCompletionFromWatchNotification(for: workout)
                
                print("📱⌚ Notification de fin de séance depuis Watch programmée avec ID: \(workout.id)")
            }
        }
    }
    
    private func notifyAppOfWorkoutCompletion(_ workout: Workout) {
        NotificationCenter.default.post(
            name: Notification.Name("WorkoutCompletedFromWatch"),
            object: workout
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        
        if activationState == .activated {
            // Envoyer les données initiales
            sendInitialData()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        
        if session.isReachable {
            // Synchroniser quand la Watch devient accessible
            sendWorkoutCount()
            sendTemplates()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingMessage(message)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func sendInitialData() {
        sendWorkoutCount()
        sendTemplates()
        sendGoals()
        sendPersonalBests()
    }
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        
        switch action {
        case "requestTemplates":
            sendTemplates()
            
        case "requestGoals":
            sendGoals()
        
        case "requestPersonalBests":
            sendPersonalBests()
            
        case "requestWorkoutCount":
            sendWorkoutCount()
            
        case "workoutCompleted":
            if let workoutData = message["workout"] as? [String: Any] {
                handleWorkoutCompleted(workoutData)
            }
            
        default:
            print("⚠️ Action non supportée: \(action)")
        }
    }
    
    // iOS only
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
