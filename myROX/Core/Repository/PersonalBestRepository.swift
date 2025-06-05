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
    func updateOrCreatePersonalBest(exerciseType: String, value: Double, unit: String, achievedAt: Date, workoutId: UUID?) async throws
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
    
    /// Met à jour ou crée un personal best localement et le synchronise avec l'API
    func updateOrCreatePersonalBest(exerciseType: String, value: Double, unit: String, achievedAt: Date, workoutId: UUID?) async throws {
        // Vérifier s'il existe déjà un record pour ce type d'exercice
        let existingPersonalBest = getCachedPersonalBest(exerciseType: exerciseType)
        
        // Pour le temps, plus petit = meilleur
        let shouldUpdateRecord = existingPersonalBest == nil || (unit == "seconds" && value < existingPersonalBest!.value)
        
        if shouldUpdateRecord {
            let formatter = ISO8601DateFormatter()
            
            if let existing = existingPersonalBest {
                // Update existing record
                existing.value = value
                existing.achievedAt = achievedAt
                existing.workoutId = workoutId
                existing.isSynced = false
                
                // Sync with API
                if let apiId = existing.apiId {
                    let updateRequest = UpdatePersonalBestRequest(
                        value: value,
                        achievedAt: formatter.string(from: achievedAt),
                        workoutId: workoutId?.uuidString
                    )
                    let updatedAPI = try await updatePersonalBest(personalBestId: apiId, updateRequest)
                    existing.updateFromAPI(updatedAPI)
                } else {
                    // Create in API if no apiId
                    let createRequest = CreatePersonalBestRequest(
                        exerciseType: exerciseType,
                        value: value,
                        unit: unit,
                        achievedAt: formatter.string(from: achievedAt),
                        workoutId: workoutId?.uuidString
                    )
                    let createdAPI = try await createPersonalBest(createRequest)
                    existing.updateFromAPI(createdAPI)
                }
            } else {
                // Create new record
                let newPersonalBest = PersonalBest(
                    exerciseType: exerciseType,
                    value: value,
                    unit: unit,
                    achievedAt: achievedAt,
                    workoutId: workoutId
                )
                
                // Save locally first
                try savePersonalBestLocally(newPersonalBest)
                
                // Then sync with API
                let createRequest = CreatePersonalBestRequest(
                    exerciseType: exerciseType,
                    value: value,
                    unit: unit,
                    achievedAt: formatter.string(from: achievedAt),
                    workoutId: workoutId?.uuidString
                )
                let createdAPI = try await createPersonalBest(createRequest)
                newPersonalBest.updateFromAPI(createdAPI)
            }
            
            try modelContext.save()
            print("🏆 Personal best updated/created: \(exerciseType) - \(value)\(unit)")
        }
    }
} 