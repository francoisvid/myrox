import Foundation
import SwiftData
import UIKit

@MainActor
class PersonalBestSyncService: ObservableObject {
    
    static let shared = PersonalBestSyncService()
    
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var error: Error?
    
    private let userDefaults = UserDefaults.standard
    private let lastSyncKey = "personal_bests_last_sync"
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var syncTimer: Timer?
    
    private init() {
        lastSyncDate = userDefaults.object(forKey: lastSyncKey) as? Date
        setupNotifications()
        startPeriodicSync()
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
        print("📱 PersonalBestSyncService: App became active, checking sync...")
        Task {
            await syncPersonalBestsIfNeeded()
        }
    }
    
    private func startPeriodicSync() {
        // Sync automatique toutes les 6 heures quand l'app est active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { _ in
            Task { @MainActor in
                print("⏰ PersonalBestSyncService: Sync périodique déclenchée")
                await self.syncPersonalBestsIfNeeded()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Synchronise les personal bests avec l'API si nécessaire
    func syncPersonalBestsIfNeeded() async {
        let modelContext = ModelContainer.shared.mainContext
        let repository = PersonalBestRepository(modelContext: modelContext)
        
        // Vérifier s'il y a des personal bests locaux
        let localPersonalBests = repository.getCachedPersonalBests()
        
        // Si pas de personal bests locaux, forcer la synchronisation
        if localPersonalBests.isEmpty {
            print("🔄 PersonalBestSyncService: Aucun personal best local - synchronisation forcée")
            await syncPersonalBests(with: repository)
            return
        }
        
        // Sinon, vérifier la temporisation
        let shouldSync = shouldPerformSync()
        
        if shouldSync {
            print("🔄 PersonalBestSyncService: Synchronisation nécessaire")
            await syncPersonalBests(with: repository)
        } else {
            print("✅ PersonalBestSyncService: Synchronisation pas nécessaire")
        }
    }
    
    /// Force la synchronisation des personal bests
    func forceSync() async {
        print("🔄 PersonalBestSyncService: Synchronisation forcée")
        let modelContext = ModelContainer.shared.mainContext
        let repository = PersonalBestRepository(modelContext: modelContext)
        await syncPersonalBests(with: repository)
    }
    
    /// Synchronise uniquement les personal bests non synchronisés
    func syncUnsyncedPersonalBests() async {
        print("🔄 PersonalBestSyncService: Synchronisation des personal bests non synchronisés")
        
        let modelContext = ModelContainer.shared.mainContext
        let repository = PersonalBestRepository(modelContext: modelContext)
        let unsyncedPersonalBests = repository.getUnsyncedPersonalBests()
        
        if unsyncedPersonalBests.isEmpty {
            print("✅ PersonalBestSyncService: Aucun personal best à synchroniser")
            return
        }
        
        print("📊 PersonalBestSyncService: \(unsyncedPersonalBests.count) personal best(s) à synchroniser")
        
        for personalBest in unsyncedPersonalBests {
            do {
                let formatter = ISO8601DateFormatter()
                
                if let apiId = personalBest.apiId {
                    // Update existing record
                    let updateRequest = UpdatePersonalBestRequest(
                        value: personalBest.value,
                        achievedAt: formatter.string(from: personalBest.achievedAt),
                        workoutId: personalBest.workoutId?.uuidString
                    )
                    let updatedAPI = try await repository.updatePersonalBest(personalBestId: apiId, updateRequest)
                    personalBest.updateFromAPI(updatedAPI)
                } else {
                    // Create new record
                    let createRequest = CreatePersonalBestRequest(
                        exerciseType: personalBest.exerciseType,
                        value: personalBest.value,
                        unit: personalBest.unit,
                        achievedAt: formatter.string(from: personalBest.achievedAt),
                        workoutId: personalBest.workoutId?.uuidString
                    )
                    let createdAPI = try await repository.createPersonalBest(createRequest)
                    personalBest.updateFromAPI(createdAPI)
                }
                
                print("✅ Personal Best synchronisé: \(personalBest.exerciseType) - \(personalBest.value)\(personalBest.unit)")
            } catch {
                print("❌ Erreur sync personal best \(personalBest.exerciseType): \(error)")
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Erreur sauvegarde personal bests: \(error)")
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
    
    private func syncPersonalBests(with repository: PersonalBestRepository) async {
        guard !isLoading else {
            print("⚠️ PersonalBestSyncService: Synchronisation déjà en cours")
            return
        }
        
        isLoading = true
        error = nil
        
        // Démarrer une tâche en arrière-plan
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "PersonalBestSync") {
            self.endBackgroundTask()
        }
        
        do {
            print("🌐 PersonalBestSyncService: Synchronisation avec l'API...")
            
            // Synchroniser avec l'API
            try await repository.syncPersonalBestsWithCache()
            
            // Mettre à jour la date de dernière synchronisation
            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: lastSyncKey)
            
            print("🎯 PersonalBestSyncService: Synchronisation terminée avec succès")
            
        } catch {
            self.error = error
            print("❌ PersonalBestSyncService: Erreur de synchronisation - \(error)")
            
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
        return true // Assumer que c'est une erreur réseau par défaut
    }
    
    private func scheduleRetry() {
        print("🔄 PersonalBestSyncService: Retry programmé dans 30 secondes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            Task {
                await self.syncPersonalBestsIfNeeded()
            }
        }
    }
    
    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
} 