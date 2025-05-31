import SwiftUI
import SwiftData
import Foundation

@MainActor
class NotificationNavigationService: ObservableObject {
    static let shared = NotificationNavigationService()
    
    // États pour gérer l'ouverture des vues
    @Published var shouldShowWorkoutCompletion = false
    @Published var workoutToShow: Workout?
    @Published var selectedTab: Int = 0
    
    private init() {}
    
    // MARK: - Navigation depuis notifications
    
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "workout-completion", "workout-completion-watch":
            handleWorkoutCompletionNotification(userInfo: userInfo)
        case "personal-record":
            handlePersonalRecordNotification(userInfo: userInfo)
        default:
            break
        }
    }
    
    // MARK: - Gestion des différents types de notifications
    
    private func handleWorkoutCompletionNotification(userInfo: [AnyHashable: Any]) {
        guard let workoutIdString = userInfo["workoutId"] as? String,
              let workoutId = UUID(uuidString: workoutIdString) else {
            print("❌ ID de workout invalide dans la notification")
            return
        }
        
        print("🔍 Recherche du workout avec ID: \(workoutId)")
        
        // Récupérer le workout depuis la base de données
        Task {
            if let workout = await fetchWorkout(id: workoutId) {
                print("✅ Workout trouvé: \(workout.templateName ?? "Sans nom")")
                
                // Ouvrir la modale de récapitulatif
                self.workoutToShow = workout
                self.shouldShowWorkoutCompletion = true
                
                // Si c'est une notification Watch, aller sur l'onglet Statistiques
                if userInfo["source"] as? String == "watch" {
                    self.selectedTab = 2 // Onglet Statistiques
                }
            } else {
                print("❌ Workout introuvable avec l'ID: \(workoutId)")
                // Fallback : aller sur l'onglet Statistiques
                self.selectedTab = 2
            }
        }
    }
    
    private func handlePersonalRecordNotification(userInfo: [AnyHashable: Any]) {
        print("🏆 Ouverture des statistiques pour voir le record")
        // Aller directement sur l'onglet Statistiques
        selectedTab = 2
    }
    
    // MARK: - Méthodes utilitaires
    
    private func fetchWorkout(id: UUID) async -> Workout? {
        let modelContext = ModelContainer.shared.mainContext
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.id == id
            }
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            return workouts.first
        } catch {
            print("❌ Erreur lors de la récupération du workout: \(error)")
            return nil
        }
    }
    
    // MARK: - Reset state
    
    func resetNavigationState() {
        shouldShowWorkoutCompletion = false
        workoutToShow = nil
    }
    
    // MARK: - Test method (DEBUG only)
    #if DEBUG
    func testNotificationTap(with workout: Workout) {
        print("🧪 Test d'ouverture de modale depuis notification")
        workoutToShow = workout
        shouldShowWorkoutCompletion = true
    }
    #endif
} 