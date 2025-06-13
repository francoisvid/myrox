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
        
        return try await apiService.post(endpoints.personalTemplates, body: template, responseType: APITemplate.self)
    }
    
    func updateTemplate(_ template: UpdateTemplateRequest) async throws -> APITemplate {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        guard let templateUUID = UUID(uuidString: template.id) else {
            throw APIError.invalidURL
        }
        
        return try await apiService.put(endpoints.updatePersonalTemplate(templateId: templateUUID), body: template, responseType: APITemplate.self)
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
        print("✅ TemplateRepository.deleteTemplate - Suppression réussie")
    }
    
    // MARK: - Cache Management
    
    func syncTemplatesWithCache() async throws {
        // 1. Fetch from API
        let personalTemplates = try await fetchPersonalTemplates()
        let assignedTemplates = try await fetchAssignedTemplates()
        let allAPITemplates = personalTemplates + assignedTemplates
        
        // 2. Get existing cached templates
        let existingTemplates = getCachedTemplates()
        let existingTemplateIds = Set(existingTemplates.map { $0.id })
        
        // 3. Determine which templates to update/add/remove
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
                // Update existing template
                existingTemplate.name = apiTemplate.name
                existingTemplate.rounds = apiTemplate.rounds
                
                // Update exercises
                print("🔄 Mise à jour template existant: \(existingTemplate.name)")
                existingTemplate.exercises.removeAll()
                for apiExercise in apiTemplate.exercises {
                    print("📋 Mise à jour exercice: \(apiExercise.exercise.name)")
                    print("   - distance: \(apiExercise.distance ?? 0) -> targetDistance: \(apiExercise.targetDistance ?? 0)")
                    print("   - reps: \(apiExercise.reps ?? 0) -> targetReps: \(apiExercise.targetReps ?? 0)")
                    
                    let templateExercise = TemplateExercise(
                        exerciseName: apiExercise.exercise.name,
                        targetDistance: apiExercise.targetDistance,
                        targetRepetitions: apiExercise.targetReps,
                        order: apiExercise.order
                    )
                    
                    print("   ✅ TemplateExercise mis à jour: targetDistance=\(templateExercise.targetDistance ?? 0), targetRepetitions=\(templateExercise.targetRepetitions ?? 0)")
                    existingTemplate.exercises.append(templateExercise)
                }
            } else {
                // Add new template
                let newTemplate = convertAPITemplateToSwiftData(apiTemplate)
                modelContext.insert(newTemplate)
            }
        }
        
        try modelContext.save()
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
                order: apiExercise.order
            )
            
            print("   ✅ TemplateExercise créé: targetDistance=\(templateExercise.targetDistance ?? 0), targetRepetitions=\(templateExercise.targetRepetitions ?? 0)")
            
            template.exercises.append(templateExercise)
        }
        
        return template
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