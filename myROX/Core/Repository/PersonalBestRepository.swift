import Foundation
import SwiftData
import FirebaseAuth

protocol PersonalBestRepositoryProtocol {
    // API Methods
    func fetchPersonalBests() async throws -> [APIPersonalBest]
    func createPersonalBest(_ request: CreatePersonalBestRequest) async throws -> APIPersonalBest
    func updatePersonalBest(personalBestId: String, _ request: UpdatePersonalBestRequest) async throws -> APIPersonalBest
    func deletePersonalBest(personalBestId: String) async throws
    
    // Local Cache Methods  
    func syncPersonalBestsWithCache() async throws
    func getCachedPersonalBests() -> [PersonalBest]
    func getCachedPersonalBest(exerciseType: String) -> PersonalBest?
    func getUnsyncedPersonalBests() -> [PersonalBest]
    
    // Local PersonalBest Management
    func savePersonalBestLocally(_ personalBest: PersonalBest) throws
}

class PersonalBestRepository: PersonalBestRepositoryProtocol {
    private let apiService: APIService
    private let modelContext: ModelContext
    
    init(apiService: APIService = APIService.shared, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
    }
    
    // MARK: - API Methods
    
    func fetchPersonalBests() async throws -> [APIPersonalBest] {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.fetchPersonalBests(firebaseUID: endpoints.firebaseUID)
    }
    
    func createPersonalBest(_ request: CreatePersonalBestRequest) async throws -> APIPersonalBest {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.createPersonalBest(firebaseUID: endpoints.firebaseUID, request)
    }
    
    func updatePersonalBest(personalBestId: String, _ request: UpdatePersonalBestRequest) async throws -> APIPersonalBest {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.updatePersonalBest(firebaseUID: endpoints.firebaseUID, personalBestId: personalBestId, request)
    }
    
    func deletePersonalBest(personalBestId: String) async throws {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        try await apiService.deletePersonalBest(firebaseUID: endpoints.firebaseUID, personalBestId: personalBestId)
    }
    
    // MARK: - Cache Management
    
    func syncPersonalBestsWithCache() async throws {
        // 1. Fetch personal bests from API
        let apiPersonalBests = try await fetchPersonalBests()
        
        // 2. Get existing cached personal bests
        let existingPersonalBests = getCachedPersonalBests()
        let existingPersonalBestsByType = Dictionary(uniqueKeysWithValues: existingPersonalBests.map { ($0.exerciseType, $0) })
        
        // 3. Determine which personal bests to update/add/remove
        let apiPersonalBestsByType = Dictionary(uniqueKeysWithValues: apiPersonalBests.map { ($0.exerciseType, $0) })
        
        // Remove personal bests that no longer exist in API
        for personalBest in existingPersonalBests {
            if apiPersonalBestsByType[personalBest.exerciseType] == nil {
                modelContext.delete(personalBest)
            }
        }
        
        // Add or update personal bests from API
        for apiPersonalBest in apiPersonalBests {
            if let existingPersonalBest = existingPersonalBestsByType[apiPersonalBest.exerciseType] {
                // Update existing personal best
                existingPersonalBest.updateFromAPI(apiPersonalBest)
            } else {
                // Add new personal best
                let newPersonalBest = PersonalBest.fromAPI(apiPersonalBest)
                modelContext.insert(newPersonalBest)
            }
        }
        
        // Save changes
        try modelContext.save()
    }
    
    func getCachedPersonalBests() -> [PersonalBest] {
        let descriptor = FetchDescriptor<PersonalBest>(
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching cached personal bests: \(error)")
            return []
        }
    }
    
    func getCachedPersonalBest(exerciseType: String) -> PersonalBest? {
        let descriptor = FetchDescriptor<PersonalBest>(
            predicate: #Predicate { $0.exerciseType == exerciseType }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching personal best for exercise type \(exerciseType): \(error)")
            return nil
        }
    }
    
    func getUnsyncedPersonalBests() -> [PersonalBest] {
        let descriptor = FetchDescriptor<PersonalBest>(
            predicate: #Predicate { $0.isSynced == false },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching unsynced personal bests: \(error)")
            return []
        }
    }
    
    // MARK: - Local PersonalBest Management
    
    func savePersonalBestLocally(_ personalBest: PersonalBest) throws {
        modelContext.insert(personalBest)
        try modelContext.save()
    }
    
    // MARK: - SUPPRIMÉ - Optimisation P0
    // 
    // La méthode updateOrCreatePersonalBest() a été supprimée dans le cadre de l'optimisation P0
    // Elle créait un double calcul des Personal Bests avec l'API
    // 
    // ✅ Nouvelle stratégie optimisée :
    // 1. L'API calcule automatiquement les Personal Bests lors de la sync des workouts
    // 2. L'iPhone récupère les résultats via syncPersonalBestsWithCache()
    // 3. Plus de double calcul = -50% trafic réseau + source de vérité unique
} 