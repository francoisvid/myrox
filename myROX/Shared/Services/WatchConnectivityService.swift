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
    
    func sendTemplates() {
        guard session.isReachable else { return }
        
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        
        do {
            let templates = try modelContext.fetch(descriptor)
            let templatesData = templates.map { template in
                [
                    "id": template.id.uuidString,
                    "name": template.name,
                    "exercises": template.exerciseNames
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
    
    // MARK: - Receive from Watch
    
    func handleWorkoutCompleted(_ workoutData: [String: Any]) {
        // Créer un nouveau workout depuis les données Watch
        let workout = Workout()
        
        if let exercises = workoutData["exercises"] as? [[String: Any]] {
            for exerciseData in exercises {
                let exercise = WorkoutExercise(
                    exerciseName: exerciseData["name"] as? String ?? ""
                )
                exercise.duration = exerciseData["duration"] as? TimeInterval ?? 0
                exercise.distance = exerciseData["distance"] as? Double ?? 0
                exercise.repetitions = exerciseData["repetitions"] as? Int ?? 0
                
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
        
        // Sauvegarder
        modelContext.insert(workout)
        try? modelContext.save()
        
        // Notifier l'app
        NotificationCenter.default.post(
            name: Notification.Name("WorkoutCompletedFromWatch"),
            object: nil
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
