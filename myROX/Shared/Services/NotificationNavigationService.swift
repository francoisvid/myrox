import SwiftUI
import SwiftData
import Foundation

@MainActor
class NotificationNavigationService: ObservableObject {
    static let shared = NotificationNavigationService()
    
    // MARK: - Published Properties
    @Published var shouldShowWorkoutCompletion = false
    @Published var workoutToShow: Workout?
    @Published var selectedTab: Int = 0
    
    // MARK: - Constants
    private enum RetryConfiguration {
        static let maxRetriesWatch = 5
        static let maxRetriesPhone = 3
        static let waitTimeWatch: UInt64 = 3_000_000_000 // 3 secondes
        static let waitTimePhone: UInt64 = 1_000_000_000 // 1 seconde
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Point d'entrée principal pour gérer les taps sur notifications
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { 
            print("⚠️ Type de notification manquant")
            return 
        }
        
        switch type {
        case "workout-completion", "workout-completion-watch":
            handleWorkoutCompletionNotification(userInfo: userInfo)
        case "personal-record":
            handlePersonalRecordNotification(userInfo: userInfo)
        default:
            print("⚠️ Type de notification non supporté: \(type)")
        }
    }
    
    /// Réinitialise l'état de navigation
    func resetNavigationState() {
        shouldShowWorkoutCompletion = false
        workoutToShow = nil
    }
    
    // MARK: - Private Methods - Notification Handlers
    
    private func handleWorkoutCompletionNotification(userInfo: [AnyHashable: Any]) {
        guard let workoutIdString = userInfo["workoutId"] as? String,
              let workoutId = UUID(uuidString: workoutIdString) else {
            print("❌ ID de workout invalide dans la notification")
            return
        }
        
        let isWatchNotification = userInfo["source"] as? String == "watch"
        let source = isWatchNotification ? "Watch" : "iPhone"
        
        print("🔍 Recherche du workout \(source) avec ID: \(workoutId)")
        
        Task {
            let workout = await fetchWorkoutWithStrategy(
                id: workoutId, 
                isWatchNotification: isWatchNotification
            )
            
            await handleWorkoutFetchResult(workout: workout, isWatchNotification: isWatchNotification)
        }
    }
    
    private func handlePersonalRecordNotification(userInfo: [AnyHashable: Any]) {
        print("🏆 Ouverture des statistiques pour voir le record")
        selectedTab = 2 // Onglet Statistiques
    }
    
    // MARK: - Private Methods - Workout Fetching
    
    /// Stratégie de récupération selon le type de notification
    private func fetchWorkoutWithStrategy(id: UUID, isWatchNotification: Bool) async -> Workout? {
        if isWatchNotification {
            // Notifications Watch : retry avec synchronisation API
            return await fetchWorkoutWithRetry(
                id: id, 
                maxRetries: RetryConfiguration.maxRetriesWatch, 
                waitTime: RetryConfiguration.waitTimeWatch,
                shouldSync: true
            )
        } else {
            // Notifications iPhone : tentative simple
            return await fetchWorkout(id: id)
        }
    }
    
    /// Récupération simple d'un workout
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
    
    /// Récupération avec retry et synchronisation pour les notifications Watch
    private func fetchWorkoutWithRetry(
        id: UUID, 
        maxRetries: Int, 
        waitTime: UInt64,
        shouldSync: Bool
    ) async -> Workout? {
        let modelContext = ModelContainer.shared.mainContext
        
        for attempt in 1...maxRetries {
            print("🔄 Tentative \(attempt)/\(maxRetries) de récupération du workout \(id)")
            
            // Essayer de récupérer le workout localement
            if let workout = await fetchWorkout(id: id) {
                print("✅ Workout trouvé à la tentative \(attempt)")
                return workout
            }
            
            // Si pas trouvé et qu'il reste des tentatives, synchroniser depuis l'API
            if attempt < maxRetries && shouldSync {
                await performWorkoutSync()
                
                // Attendre avant la prochaine tentative
                do {
                    try await Task.sleep(nanoseconds: waitTime)
                } catch {
                    print("⚠️ Interruption du délai d'attente: \(error)")
                }
            }
        }
        
        print("❌ Workout \(id) introuvable après \(maxRetries) tentatives")
        return nil
    }
    
    /// Synchronisation des workouts depuis l'API
    private func performWorkoutSync() async {
        print("⏳ Synchronisation des workouts depuis l'API...")
        
        do {
            let modelContext = ModelContainer.shared.mainContext
            let workoutRepository = WorkoutRepository(modelContext: modelContext)
            try await workoutRepository.syncWorkoutsWithCache()
            print("✅ Synchronisation des workouts terminée")
        } catch {
            print("❌ Erreur lors de la synchronisation: \(error)")
        }
    }
    
    // MARK: - Private Methods - Result Handling
    
    private func handleWorkoutFetchResult(workout: Workout?, isWatchNotification: Bool) async {
        if let workout = workout {
            print("✅ Workout trouvé: \(workout.templateName ?? "Sans nom")")
            
            // Ouvrir la modale de récapitulatif
            self.workoutToShow = workout
            self.shouldShowWorkoutCompletion = true
            
            // Si c'est une notification Watch, aller aussi sur l'onglet Statistiques
            if isWatchNotification {
                self.selectedTab = 2 // Onglet Statistiques
            }
        } else {
            print("❌ Workout introuvable - Redirection vers les statistiques")
            // Fallback : aller sur l'onglet Statistiques
            self.selectedTab = 2
        }
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// Méthode de test pour simuler un tap sur notification
    func testNotificationTap(with workout: Workout) {
        print("🧪 Test d'ouverture de modale depuis notification")
        workoutToShow = workout
        shouldShowWorkoutCompletion = true
    }
    #endif
} 