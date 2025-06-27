import Foundation
import SwiftData
import FirebaseAuth

protocol TemplateRepositoryProtocol {
    // API Methods
    func fetchPersonalTemplates() async throws -> [APITemplate]
    func fetchAssignedTemplates() async throws -> [APITemplate]
    func createTemplate(_ template: CreateTemplateRequest) async throws -> APITemplate
    func updateTemplate(_ template: UpdateTemplateRequest) async throws -> APITemplate
    func deleteTemplate(id: String) async throws
    
    // Local Cache Methods  
    func syncTemplatesWithCache() async throws
    func getCachedTemplates() -> [WorkoutTemplate]
    func getCachedTemplate(id: UUID) -> WorkoutTemplate?
}

class TemplateRepository: TemplateRepositoryProtocol {
    private let apiService: APIService
    private let modelContext: ModelContext
    
    // 🚀 OPTIMISATION P0 #3: Cache intelligent des Templates pour éviter les syncs répétées
    private static var templateCache: [APITemplate] = []
    private static var cacheLastUpdated: Date?
    private static let cacheValidityDuration: TimeInterval = 600 // 10 minutes (templates moins volatils)
    private static var isSyncing = false // Éviter les syncs multiples simultanées
    
    init(apiService: APIService = APIService.shared, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
    }
    
    // MARK: - API Methods
    
    func fetchPersonalTemplates() async throws -> [APITemplate] {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.get(endpoints.personalTemplates, responseType: [APITemplate].self)
    }
    
    func fetchAssignedTemplates() async throws -> [APITemplate] {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.get(endpoints.assignedTemplates, responseType: [APITemplate].self)
    }
    
    func createTemplate(_ template: CreateTemplateRequest) async throws -> APITemplate {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        let result = try await apiService.post(endpoints.personalTemplates, body: template, responseType: APITemplate.self)
        
        // 🚀 OPTIMISATION P0 #3: Invalider le cache après création
        Self.invalidateTemplateCache()
        
        return result
    }
    
    func updateTemplate(_ template: UpdateTemplateRequest) async throws -> APITemplate {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        guard let templateUUID = UUID(uuidString: template.id) else {
            throw APIError.invalidURL
        }
        
        let result = try await apiService.put(endpoints.updatePersonalTemplate(templateId: templateUUID), body: template, responseType: APITemplate.self)
        
        // 🚀 OPTIMISATION P0 #3: Invalider le cache après mise à jour
        Self.invalidateTemplateCache()
        
        return result
    }
    
    func deleteTemplate(id: String) async throws {
        print("🗑️ TemplateRepository.deleteTemplate - ID reçu: '\(id)'")
        
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            print("❌ TemplateRepository.deleteTemplate - Pas d'endpoints (utilisateur non connecté)")
            throw APIError.unauthorized
        }
        
        guard let templateUUID = UUID(uuidString: id) else {
            print("❌ TemplateRepository.deleteTemplate - UUID invalide: '\(id)'")
            throw APIError.invalidURL
        }
        
        print("🆔 TemplateRepository.deleteTemplate - UUID construit: \(templateUUID)")
        print("🆔 TemplateRepository.deleteTemplate - UUID.uuidString: \(templateUUID.uuidString)")
        print("🆔 TemplateRepository.deleteTemplate - UUID.uuidString.lowercased(): \(templateUUID.uuidString.lowercased())")
        
        let deleteEndpoint = endpoints.deletePersonalTemplate(templateId: templateUUID)
        print("🌐 TemplateRepository.deleteTemplate - Endpoint path: \(deleteEndpoint.path)")
        
        let _: DeleteResponse = try await apiService.delete(deleteEndpoint, responseType: DeleteResponse.self)
        
        // 🚀 OPTIMISATION P0 #3: Invalider le cache après suppression
        Self.invalidateTemplateCache()
        
        print("✅ TemplateRepository.deleteTemplate - Suppression réussie")
    }
    
    // MARK: - Cache Management
    
    // 🚀 OPTIMISATION P0 #3: Sync intelligente avec cache des Templates
    func syncTemplatesWithCache() async throws {
        // 1. Vérifier le cache d'abord
        if let lastUpdated = Self.cacheLastUpdated,
           Date().timeIntervalSince(lastUpdated) < Self.cacheValidityDuration,
           !Self.templateCache.isEmpty {
            // Cache valide, utiliser les données en cache
            try await syncFromCache(Self.templateCache)
            print("✅ Templates synchronisés depuis le cache (optimisation P0 #3)")
            return
        }
        
        // 2. Éviter les syncs multiples simultanées
        guard !Self.isSyncing else {
            print("⚠️ Sync des templates déjà en cours, ignorée")
            return
        }
        
        Self.isSyncing = true
        
        do {
            // 3. Fetch depuis l'API et mettre à jour le cache
            print("🔄 Reconstruction du cache Templates depuis l'API (optimisation P0 #3)...")
            
            let personalTemplates = try await fetchPersonalTemplates()
            let assignedTemplates = try await fetchAssignedTemplates()
            let allAPITemplates = personalTemplates + assignedTemplates
            
            // 4. Mettre à jour le cache
            Self.templateCache = allAPITemplates
            Self.cacheLastUpdated = Date()
            
            // 5. Synchroniser avec la base locale
            try await syncFromCache(allAPITemplates)
            
            print("✅ Cache Templates reconstruit: \(allAPITemplates.count) templates")
            print("   - Personnels: \(personalTemplates.count)")
            print("   - Assignés: \(assignedTemplates.count)")
            
        } catch {
            print("❌ Erreur sync Templates: \(error)")
            throw error
        }
        
        Self.isSyncing = false
    }
    
    // 🚀 OPTIMISATION P0 #3: Synchronisation depuis le cache (méthode privée optimisée)
    private func syncFromCache(_ allAPITemplates: [APITemplate]) async throws {
        // Get existing cached templates
        let existingTemplates = getCachedTemplates()
        let existingTemplateIds = Set(existingTemplates.map { $0.id })
        
        // Determine which templates to update/add/remove
        let apiTemplateIds = Set(allAPITemplates.map { $0.uuid })
        
        // Remove templates that no longer exist in API
        for template in existingTemplates {
            if !apiTemplateIds.contains(template.id) {
                modelContext.delete(template)
            }
        }
        
        // Add or update templates from API
        for apiTemplate in allAPITemplates {
            if let existingTemplate = existingTemplates.first(where: { $0.id == apiTemplate.uuid }) {
                updateExistingTemplate(existingTemplate, from: apiTemplate)
            } else {
                // Add new template
                let newTemplate = convertAPITemplateToSwiftData(apiTemplate)
                modelContext.insert(newTemplate)
            }
        }
        
        try modelContext.save()
    }
    
    // 🚀 OPTIMISATION P0 #3: Méthode optimisée pour update un template existant
    private func updateExistingTemplate(_ existingTemplate: WorkoutTemplate, from apiTemplate: APITemplate) {
        // Update basic properties
        existingTemplate.name = apiTemplate.name
        existingTemplate.rounds = apiTemplate.rounds
        
        // Update exercises efficiently
        existingTemplate.exercises.removeAll()
        for apiExercise in apiTemplate.exercises {
            let templateExercise = TemplateExercise(
                exerciseName: apiExercise.exercise.name,
                targetDistance: apiExercise.targetDistance,
                targetRepetitions: apiExercise.targetReps,
                targetDuration: apiExercise.targetDuration != nil ? TimeInterval(apiExercise.targetDuration!) : nil,
                order: apiExercise.order
            )
            existingTemplate.exercises.append(templateExercise)
        }
    }
    
    func getCachedTemplates() -> [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("⚠️ Error fetching cached templates: \(error)")
            return []
        }
    }
    
    func getCachedTemplate(id: UUID) -> WorkoutTemplate? {
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("⚠️ Error fetching cached template: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func clearTemplateCache() {
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        
        do {
            let existingTemplates = try modelContext.fetch(descriptor)
            for template in existingTemplates {
                modelContext.delete(template)
            }
        } catch {
            print("⚠️ Error clearing template cache: \(error)")
        }
    }
    
    private func convertAPITemplateToSwiftData(_ apiTemplate: APITemplate) -> WorkoutTemplate {
        let template = WorkoutTemplate(id: apiTemplate.uuid, name: apiTemplate.name, rounds: apiTemplate.rounds)
        
        print("🔄 Conversion template API vers SwiftData: \(apiTemplate.name)")
        
        // Convert API exercises to SwiftData TemplateExercise
        for apiExercise in apiTemplate.exercises {
            print("📋 Exercice API: \(apiExercise.exercise.name)")
            print("   - distance: \(apiExercise.distance ?? 0) -> targetDistance: \(apiExercise.targetDistance ?? 0)")
            print("   - reps: \(apiExercise.reps ?? 0) -> targetReps: \(apiExercise.targetReps ?? 0)")
            
            let templateExercise = TemplateExercise(
                exerciseName: apiExercise.exercise.name,
                targetDistance: apiExercise.targetDistance,
                targetRepetitions: apiExercise.targetReps,
                targetDuration: apiExercise.targetDuration != nil ? TimeInterval(apiExercise.targetDuration!) : nil,
                order: apiExercise.order
            )
            
            print("   ✅ TemplateExercise créé: targetDistance=\(templateExercise.targetDistance ?? 0), targetRepetitions=\(templateExercise.targetRepetitions ?? 0)")
            
            template.exercises.append(templateExercise)
        }
        
        return template
    }
    
    // 🚀 OPTIMISATION P0 #3: Méthodes de gestion du cache
    
    /// Invalide le cache des templates (à appeler après create/update/delete)
    static func invalidateTemplateCache() {
        templateCache.removeAll()
        cacheLastUpdated = nil
        isSyncing = false
        print("🧹 Cache Templates invalidé")
    }
    
    /// Force le rafraîchissement du cache au prochain appel
    static func forceRefreshCache() {
        cacheLastUpdated = nil
        print("🔄 Cache Templates marqué pour rafraîchissement")
    }
    
    /// Vérifie si le cache est valide
    static func isCacheValid() -> Bool {
        guard let lastUpdated = cacheLastUpdated else { return false }
        return Date().timeIntervalSince(lastUpdated) < cacheValidityDuration && !templateCache.isEmpty
    }
}

// MARK: - Mock Repository for Testing

class MockTemplateRepository: TemplateRepositoryProtocol {
    var shouldFail = false
    var mockTemplates: [APITemplate] = []
    
    func fetchPersonalTemplates() async throws -> [APITemplate] {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return mockTemplates
    }
    
    func fetchAssignedTemplates() async throws -> [APITemplate] {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return []
    }
    
    func createTemplate(_ template: CreateTemplateRequest) async throws -> APITemplate {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return APITemplate(
            id: UUID().uuidString,
            name: template.name,
            rounds: template.rounds,
            description: nil,
            difficulty: "BEGINNER",
            estimatedTime: 30,
            category: "FUNCTIONAL",
            isPersonal: true,
            isActive: true,
            exercises: [],
            userId: "mock-user",
            coachId: nil,
            createdAt: Date().apiString,
            updatedAt: Date().apiString
        )
    }
    
    func updateTemplate(_ template: UpdateTemplateRequest) async throws -> APITemplate {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return mockTemplates.first ?? APITemplate(
            id: template.id,
            name: template.name ?? "Mock Template",
            rounds: template.rounds ?? 1,
            description: nil,
            difficulty: "BEGINNER",
            estimatedTime: 30,
            category: "FUNCTIONAL",
            isPersonal: true,
            isActive: true,
            exercises: [],
            userId: "mock-user",
            coachId: nil,
            createdAt: Date().apiString,
            updatedAt: Date().apiString
        )
    }
    
    func deleteTemplate(id: String) async throws {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
    }
    
    func syncTemplatesWithCache() async throws {
        // Mock implementation - no-op
    }
    
    func getCachedTemplates() -> [WorkoutTemplate] {
        return []
    }
    
    func getCachedTemplate(id: UUID) -> WorkoutTemplate? {
        return nil
    }
} 