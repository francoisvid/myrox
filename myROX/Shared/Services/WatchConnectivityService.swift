import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isReachable = false
    private var session: WCSession
    private let modelContext: ModelContext
    
    override init() {
        self.session = WCSession.default
        self.modelContext = ModelContainer.shared.mainContext
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send Data to Watch
    
    func sendWorkoutCount() {
        guard session.isReachable else { return }
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.completedAt != nil }
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            let message = ["workoutCount": workouts.count]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("Erreur envoi workout count: \(error)")
            }
        } catch {
            print("Erreur fetch workouts: \(error)")
        }
    }
    
    func sendWorkoutDeleted(_ workoutId: UUID) {
        guard session.isReachable else { return }
        
        let message = [
            "action": "workoutDeleted",
            "workoutId": workoutId.uuidString
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur envoi suppression workout: \(error)")
        }
    }
    
    func sendTemplateDeleted(_ templateId: UUID) {
        guard session.isReachable else { return }
        
        let message = [
            "action": "templateDeleted",
            "templateId": templateId.uuidString
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur envoi suppression template: \(error)")
        }
    }
    
    func sendTemplates() {
        guard session.isReachable else { return }
        
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        
        do {
            let templates = try modelContext.fetch(descriptor)
            let templatesData = templates.map { template in
                // Utiliser uniquement les TemplateExercise
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
            
            let message = ["templates": templatesData]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("Erreur envoi templates: \(error)")
            }
        } catch {
            print("Erreur fetch templates: \(error)")
        }
    }
    
    func sendActiveWorkout(_ workout: Workout) {
        guard session.isReachable else { return }
        
        let workoutData: [String: Any] = [
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
        
        let message = ["activeWorkout": workoutData]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Erreur envoi workout actif: \(error)")
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
                print("Erreur envoi goals: \(error)")
            }
        } catch {
            print("Erreur fetch goals: \(error)")
        }
    }
    
    // MARK: - Receive from Watch
    
    func handleWorkoutCompleted(_ workoutData: [String: Any]) {
        // Créer un nouveau workout depuis les données Watch
        let workout = Workout()
        
        // Récupérer le templateId si disponible  
        if let templateIdString = workoutData["templateId"] as? String,
           !templateIdString.isEmpty,
           let templateId = UUID(uuidString: templateIdString) {
            workout.templateID = templateId
        }
        
        // Récupérer le nom du template si disponible
        if let templateName = workoutData["templateName"] as? String {
            workout.templateName = templateName
        }
        
        // Récupérer les exercices
        if let exercises = workoutData["exercises"] as? [[String: Any]] {
            for exerciseData in exercises {
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
                
                workout.performances.append(exercise)
            }
        }
        
        workout.completedAt = Date()
        workout.totalDuration = workoutData["totalDuration"] as? TimeInterval ?? 0
        workout.totalDistance = workoutData["totalDistance"] as? Double ?? 0
        
        // Récupérer la vraie heure de début si disponible
        if let startedAtTimestamp = workoutData["startedAt"] as? TimeInterval {
            workout.startedAt = Date(timeIntervalSince1970: startedAtTimestamp)
        }
        
        // Sauvegarder
        modelContext.insert(workout)
        try? modelContext.save()
        
        // 🚀 NOUVEAU : Synchroniser avec l'API en arrière-plan
        Task {
            do {
                let workoutRepository = WorkoutRepository(modelContext: modelContext)
                try await workoutRepository.syncCompletedWorkout(workout)
                print("✅ Workout Watch synchronisé avec l'API")
            } catch {
                print("⚠️ Erreur synchronisation API workout Watch (workout sauvé localement): \(error)")
                // Le workout reste sauvé localement même si la sync API échoue
                // isSynced reste à false pour une prochaine tentative
            }
        }
        
        // 🔔 NOUVEAU : Déclencher des notifications pour la séance terminée depuis la Watch
        Task { @MainActor in
            print("🏋️ Séance terminée depuis la Watch - Envoi de notification")
            
            // Notification spécifique pour les séances Watch
            await NotificationService.shared.scheduleWorkoutCompletionFromWatchNotification(for: workout)
            
            // Vérifier et notifier les nouveaux records personnels
            // TODO: Calculer les records depuis la Watch plus tard
            
            print("📱⌚ Notification de fin de séance depuis Watch programmée")
        }
        
        // Notifier l'app
        NotificationCenter.default.post(
            name: Notification.Name("WorkoutCompletedFromWatch"),
            object: workout // Passer le workout comme objet
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
            sendWorkoutCount()
            sendTemplates()
            sendGoals()
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
            if let action = message["action"] as? String {
                switch action {
                case "requestTemplates":
                    self.sendTemplates()
                    
                case "requestGoals":
                    self.sendGoals()
                    
                case "requestWorkoutCount":
                    self.sendWorkoutCount()
                    
                case "workoutCompleted":
                    if let workoutData = message["workout"] as? [String: Any] {
                        self.handleWorkoutCompleted(workoutData)
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    // iOS only
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
