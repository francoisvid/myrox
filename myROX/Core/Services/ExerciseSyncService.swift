import Foundation
import SwiftData
import UIKit
import UserNotifications

@MainActor
class ExerciseSyncService: ObservableObject {
    
    static let shared = ExerciseSyncService()
    
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var error: Error?
    @Published var newExercisesCount = 0
    
    private let apiService = APIService.shared
    private let userDefaults = UserDefaults.standard
    private let lastSyncKey = "exercises_last_sync"
    
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
        print("📱 ExerciseSyncService: App became active, checking sync...")
        Task {
            await syncExercisesIfNeeded(modelContext: ModelContainer.shared.mainContext)
        }
    }
    
    private func startPeriodicSync() {
        // Sync automatique toutes les 4 heures quand l'app est active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 4 * 3600, repeats: true) { _ in
            Task { @MainActor in
                print("⏰ ExerciseSyncService: Sync périodique déclenchée")
                await self.syncExercisesIfNeeded(modelContext: ModelContainer.shared.mainContext)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Synchronise les exercices avec l'API si nécessaire
    func syncExercisesIfNeeded(modelContext: ModelContext) async {
        // Vérifier s'il y a des exercices locaux
        let descriptor = FetchDescriptor<Exercise>()
        let localExercises = (try? modelContext.fetch(descriptor)) ?? []
        
        // Si pas d'exercices locaux, forcer la synchronisation
        if localExercises.isEmpty {
            print("🔄 ExerciseSyncService: Aucun exercice local - synchronisation forcée")
            await syncExercises(modelContext: modelContext)
            return
        }
        
        // Sinon, vérifier la temporisation
        let shouldSync = shouldPerformSync()
        
        if shouldSync {
            print("🔄 ExerciseSyncService: Synchronisation nécessaire")
            await syncExercises(modelContext: modelContext)
        } else {
            print("✅ ExerciseSyncService: Synchronisation pas nécessaire")
        }
    }
    
    /// Force la synchronisation des exercices
    func forceSync(modelContext: ModelContext) async {
        print("🔄 ExerciseSyncService: Synchronisation forcée")
        await syncExercises(modelContext: modelContext)
    }
    
    /// Nettoyage complet : supprime les exercices locaux qui n'existent plus dans l'API
    func cleanupLocalExercises(modelContext: ModelContext) async -> (deleted: Int, kept: Int) {
        print("🧹 ExerciseSyncService: Début du nettoyage des exercices locaux")
        
        do {
            // Récupérer les exercices depuis l'API
            let apiExercises = try await apiService.fetchExercises()
            let apiExerciseNames = Set(apiExercises.map { $0.name })
            print("📡 ExerciseSyncService: \(apiExercises.count) exercices dans l'API")
            
            // Récupérer les exercices locaux
            let descriptor = FetchDescriptor<Exercise>()
            let localExercises = try modelContext.fetch(descriptor)
            print("📱 ExerciseSyncService: \(localExercises.count) exercices locaux")
            
            var deleted = 0
            var kept = 0
            
            // Identifier et supprimer les exercices locaux qui n'existent pas dans l'API
            for localExercise in localExercises {
                if apiExerciseNames.contains(localExercise.name) {
                    kept += 1
                } else {
                    print("🗑️ Suppression exercice local: \(localExercise.name)")
                    modelContext.delete(localExercise)
                    deleted += 1
                }
            }
            
            // Sauvegarder les changements
            try modelContext.save()
            
            print("🧹 ExerciseSyncService: Nettoyage terminé")
            print("   - Supprimés: \(deleted)")
            print("   - Conservés: \(kept)")
            
            return (deleted: deleted, kept: kept)
            
        } catch {
            print("❌ ExerciseSyncService: Erreur lors du nettoyage - \(error)")
            return (deleted: 0, kept: 0)
        }
    }
    
    /// Audit des différences entre local et API
    func auditLocalExercises(modelContext: ModelContext) async -> (onlyLocal: [String], onlyAPI: [String], common: [String]) {
        print("🔍 ExerciseSyncService: Audit des exercices local vs API")
        
        do {
            // Récupérer les exercices depuis l'API
            let apiExercises = try await apiService.fetchExercises()
            let apiExerciseNames = Set(apiExercises.map { $0.name })
            
            // Récupérer les exercices locaux
            let descriptor = FetchDescriptor<Exercise>()
            let localExercises = try modelContext.fetch(descriptor)
            let localExerciseNames = Set(localExercises.map { $0.name })
            
            // Calculer les différences
            let onlyLocal = Array(localExerciseNames.subtracting(apiExerciseNames)).sorted()
            let onlyAPI = Array(apiExerciseNames.subtracting(localExerciseNames)).sorted()
            let common = Array(localExerciseNames.intersection(apiExerciseNames)).sorted()
            
            print("📊 ExerciseSyncService: Résultats de l'audit")
            print("   - Seulement local (\(onlyLocal.count)): \(onlyLocal)")
            print("   - Seulement API (\(onlyAPI.count)): \(onlyAPI)")
            print("   - Communs (\(common.count)): \(common.count) exercices")
            
            return (onlyLocal: onlyLocal, onlyAPI: onlyAPI, common: common)
            
        } catch {
            print("❌ ExerciseSyncService: Erreur lors de l'audit - \(error)")
            return (onlyLocal: [], onlyAPI: [], common: [])
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldPerformSync() -> Bool {
        guard let lastSync = lastSyncDate else {
            print("📅 ExerciseSyncService: Première synchronisation")
            return true
        }
        
        let hoursSinceLastSync = Calendar.current.dateComponents([.hour], from: lastSync, to: Date()).hour ?? 0
        let shouldSync = hoursSinceLastSync >= 2 // Sync toutes les 2 heures max
        
        print("📅 ExerciseSyncService: Dernière sync il y a \(hoursSinceLastSync) heure(s), sync nécessaire: \(shouldSync)")
        return shouldSync
    }
    
    private func syncExercises(modelContext: ModelContext) async {
        // Éviter les syncs multiples simultanées
        guard !isLoading else {
            print("⚠️ ExerciseSyncService: Sync déjà en cours, ignorée")
            return
        }
        
        isLoading = true
        error = nil
        newExercisesCount = 0
        
        // Démarrer une tâche en arrière-plan pour éviter l'interruption
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        do {
            print("🌐 ExerciseSyncService: Récupération exercices depuis l'API...")
            
            // Récupérer les exercices depuis l'API
            let apiExercises = try await apiService.fetchExercises()
            print("✅ ExerciseSyncService: \(apiExercises.count) exercices reçus de l'API")
            
            // Récupérer les exercices locaux existants
            let descriptor = FetchDescriptor<Exercise>()
            let localExercises = try modelContext.fetch(descriptor)
            print("📱 ExerciseSyncService: \(localExercises.count) exercices locaux existants")
            
            // Synchroniser les données
            let stats = await synchronizeExercises(
                apiExercises: apiExercises,
                localExercises: localExercises,
                modelContext: modelContext
            )
            
            // Sauvegarder les changements
            try modelContext.save()
            
            // Mettre à jour la date de dernière synchronisation
            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: lastSyncKey)
            
            // Notifier s'il y a de nouveaux exercices
            newExercisesCount = stats.added
            if stats.added > 0 {
                sendNotificationForNewExercises(count: stats.added)
            }
            
            print("🎯 ExerciseSyncService: Synchronisation terminée")
            print("   - Ajoutés: \(stats.added)")
            print("   - Mis à jour: \(stats.updated)")
            print("   - Supprimés: \(stats.deleted)")
            
        } catch {
            self.error = error
            print("❌ ExerciseSyncService: Erreur de synchronisation - \(error)")
            
            // Retry automatique après 30 secondes en cas d'échec réseau
            if isNetworkError(error) {
                scheduleRetry(modelContext: modelContext)
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
    
    private func scheduleRetry(modelContext: ModelContext) {
        print("🔄 ExerciseSyncService: Programmation retry dans 30 secondes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            Task {
                await self.syncExercises(modelContext: modelContext)
            }
        }
    }
    
    private func sendNotificationForNewExercises(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Nouveaux exercices disponibles"
        content.body = "\(count) nouveaux exercices ont été ajoutés à votre catalogue"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "new-exercises-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur notification: \(error)")
            }
        }
    }
    
    private func synchronizeExercises(
        apiExercises: [APIExercise],
        localExercises: [Exercise],
        modelContext: ModelContext
    ) async -> SyncStats {
        
        var stats = SyncStats()
        
        // Créer un dictionnaire des exercices locaux par nom pour recherche rapide
        let localExercisesByName = Dictionary(grouping: localExercises, by: { $0.name })
        
        // Traiter chaque exercice de l'API
        for apiExercise in apiExercises {
            if let existingLocalExercises = localExercisesByName[apiExercise.name],
               let localExercise = existingLocalExercises.first {
                
                // Exercice existe déjà - vérifier s'il faut le mettre à jour
                if exerciseNeedsUpdate(local: localExercise, api: apiExercise) {
                    updateLocalExercise(local: localExercise, from: apiExercise)
                    stats.updated += 1
                    print("🔄 Exercice mis à jour: \(apiExercise.name)")
                }
                
            } else {
                // Nouvel exercice - l'ajouter
                let newExercise = createLocalExercise(from: apiExercise)
                modelContext.insert(newExercise)
                stats.added += 1
                print("➕ Nouvel exercice ajouté: \(apiExercise.name)")
            }
        }
        
        // Supprimer les exercices locaux qui n'existent plus dans l'API
        let apiExerciseNames = Set(apiExercises.map { $0.name })
        for localExercise in localExercises {
            if !apiExerciseNames.contains(localExercise.name) {
                modelContext.delete(localExercise)
                stats.deleted += 1
                print("🗑️ Exercice supprimé: \(localExercise.name)")
            }
        }
        
        return stats
    }
    
    private func exerciseNeedsUpdate(local: Exercise, api: APIExercise) -> Bool {
        return local.category != mapAPICategory(api.category)
    }
    
    private func updateLocalExercise(local: Exercise, from api: APIExercise) {
        local.category = mapAPICategory(api.category)
    }
    
    private func createLocalExercise(from apiExercise: APIExercise) -> Exercise {
        let exercise = Exercise(name: apiExercise.name, category: mapAPICategory(apiExercise.category))
        return exercise
    }
    
    private func mapAPICategory(_ apiCategory: String) -> String {
        switch apiCategory {
        case "HYROX_STATION": return "HYROX"
        case "RUNNING": return "Cardio"
        case "CARDIO": return "Cardio"
        case "STRENGTH": return "Force"
        case "FUNCTIONAL": return "Core"
        case "PLYOMETRIC": return "Plyo"
        default: return "Core"
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

struct SyncStats {
    var added = 0
    var updated = 0
    var deleted = 0
} 