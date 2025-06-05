import Foundation
import SwiftData
import UIKit
import UserNotifications

@MainActor
class WorkoutSyncService: ObservableObject {
    
    static let shared = WorkoutSyncService()
    
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var error: Error?
    @Published var newWorkoutsCount = 0
    
    private let workoutRepository: WorkoutRepositoryProtocol
    private let userDefaults = UserDefaults.standard
    private let lastSyncKey = "workouts_last_sync"
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var syncTimer: Timer?
    
    private init() {
        // Initialize with default repository - will be updated when model context is available
        self.workoutRepository = MockWorkoutRepository()
        lastSyncDate = userDefaults.object(forKey: lastSyncKey) as? Date
        setupNotifications()
        startPeriodicSync()
    }
    
    // Method to update repository when model context becomes available
    func updateRepository(modelContext: ModelContext) {
        // This would need to be implemented to update the repository
        // For now, we'll use dependency injection in the places where this service is used
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // Sync when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 WorkoutSyncService: App became active, checking sync...")
        Task {
            await syncWorkoutsIfNeeded()
        }
    }
    
    private func startPeriodicSync() {
        // Sync automatique toutes les 6 heures quand l'app est active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { _ in
            Task { @MainActor in
                print("⏰ WorkoutSyncService: Sync périodique déclenchée")
                await self.syncWorkoutsIfNeeded()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Synchronise les workouts avec l'API si nécessaire
    func syncWorkoutsIfNeeded() async {
        // Vérifier s'il y a des workouts locaux
        let localWorkouts = workoutRepository.getCachedWorkouts()
        
        // Si pas de workouts locaux, forcer la synchronisation
        if localWorkouts.isEmpty {
            print("🔄 WorkoutSyncService: Aucun workout local - synchronisation forcée")
            await syncWorkouts()
            return
        }
        
        // Sinon, vérifier la temporisation
        let shouldSync = shouldPerformSync()
        
        if shouldSync {
            print("🔄 WorkoutSyncService: Synchronisation nécessaire")
            await syncWorkouts()
        } else {
            print("✅ WorkoutSyncService: Synchronisation pas nécessaire")
        }
    }
    
    /// Force la synchronisation des workouts
    func forceSync() async {
        print("🔄 WorkoutSyncService: Synchronisation forcée")
        await syncWorkouts()
    }
    
    /// Synchronise les workouts complétés localement avec l'API
    func syncPendingWorkouts() async {
        print("🔄 WorkoutSyncService: Synchronisation des workouts en attente")
        
        let localWorkouts = workoutRepository.getCachedWorkouts()
        let completedWorkouts = localWorkouts.filter { $0.completedAt != nil }
        
        for workout in completedWorkouts {
            do {
                try await workoutRepository.syncCompletedWorkout(workout)
                print("✅ Workout synchronisé: \(workout.templateName ?? "Sans nom")")
            } catch {
                print("❌ Erreur sync workout \(workout.id): \(error)")
            }
        }
    }
    
    /// Synchronise uniquement les workouts non synchronisés (plus efficace)
    func syncUnsyncedWorkouts(with repository: WorkoutRepositoryProtocol) async {
        print("🔄 WorkoutSyncService: Synchronisation des workouts non synchronisés")
        
        let unsyncedWorkouts = repository.getUnsyncedWorkouts()
        
        if unsyncedWorkouts.isEmpty {
            print("✅ WorkoutSyncService: Aucun workout à synchroniser")
            return
        }
        
        print("📊 WorkoutSyncService: \(unsyncedWorkouts.count) workout(s) à synchroniser")
        
        for workout in unsyncedWorkouts {
            do {
                try await repository.syncCompletedWorkout(workout)
                print("✅ Workout synchronisé: \(workout.templateName ?? "Sans nom") (\(workout.id))")
            } catch {
                print("❌ Erreur sync workout \(workout.id): \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldPerformSync() -> Bool {
        guard let lastSync = lastSyncDate else {
            return true // Jamais synchronisé
        }
        
        // Synchroniser si plus de 4 heures depuis la dernière sync
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync > (4 * 3600)
    }
    
    private func syncWorkouts() async {
        guard !isLoading else {
            print("⚠️ WorkoutSyncService: Synchronisation déjà en cours")
            return
        }
        
        isLoading = true
        error = nil
        
        // Démarrer une tâche en arrière-plan
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "WorkoutSync") {
            self.endBackgroundTask()
        }
        
        do {
            print("🌐 WorkoutSyncService: Synchronisation avec l'API...")
            
            // Synchroniser avec l'API
            try await workoutRepository.syncWorkoutsWithCache()
            
            // Mettre à jour la date de dernière synchronisation
            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: lastSyncKey)
            
            print("🎯 WorkoutSyncService: Synchronisation terminée avec succès")
            
        } catch {
            self.error = error
            print("❌ WorkoutSyncService: Erreur de synchronisation - \(error)")
            
            // Retry automatique après 30 secondes en cas d'échec réseau
            if isNetworkError(error) {
                scheduleRetry()
            }
        }
        
        isLoading = false
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func isNetworkError(_ error: Error) -> Bool {
        // Détecter les erreurs réseau pour retry
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError, .serverError:
                return true
            default:
                return false
            }
        }
        return true // Assume network error by default
    }
    
    private func scheduleRetry() {
        print("🔄 WorkoutSyncService: Programmation retry dans 30 secondes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            Task {
                await self.syncWorkouts()
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

struct WorkoutSyncStats {
    var synced = 0
    var failed = 0
    var pending = 0
} 