import Foundation
import FirebaseAuth

protocol UserRepositoryProtocol {
    func fetchUserProfile(firebaseUID: String) async throws -> APIUser?
    func createUserProfile(_ user: APIUser) async throws -> APIUser
    func updateUserProfile(_ user: UserUpdateRequest) async throws -> APIUser
    func fetchCoach(coachId: UUID) async throws -> Coach
}

class UserRepository: UserRepositoryProtocol {
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    // MARK: - User Profile Management
    
    func fetchUserProfile(firebaseUID: String) async throws -> APIUser? {
        do {
            let user = try await apiService.get(.userProfile(firebaseUID: firebaseUID), responseType: APIUser.self)
            return user
        } catch APIError.notFound {
            // L'utilisateur n'existe pas encore dans l'API
            return nil
        } catch {
            throw error
        }
    }
    
    func createUserProfile(_ user: APIUser) async throws -> APIUser {
        return try await apiService.post(.createUser, body: user, responseType: APIUser.self)
    }
    
    func updateUserProfile(_ updateRequest: UserUpdateRequest) async throws -> APIUser {
        guard let firebaseUID = Auth.auth().currentUser?.uid else {
            throw APIError.unauthorized
        }
        
        return try await apiService.put(.updateUser(firebaseUID: firebaseUID), body: updateRequest, responseType: APIUser.self)
    }
    
    // MARK: - Coach Info (Read-only)
    
    func fetchCoach(coachId: UUID) async throws -> Coach {
        return try await apiService.get(.coach(id: coachId), responseType: Coach.self)
    }
}

// MARK: - APIUser Convenience Initializers

extension APIUser {
    // Initializer for creating new users (matches API expectations)
    init(firebaseUID: String, email: String?, displayName: String?) {
        self.id = UUID().uuidString
        self.firebaseUID = firebaseUID
        self.email = email
        self.displayName = displayName
        self.coachId = nil
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - Convenience Extensions

extension UserRepository {
    
    // Sync current Firebase user with API
    func syncCurrentUser() async throws -> APIUser {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        
        // Essayer de récupérer le profil existant
        if let existingUser = try await fetchUserProfile(firebaseUID: firebaseUser.uid) {
            return existingUser
        }
        
        // Créer un nouveau profil
        let newUser = APIUser(
            firebaseUID: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName
        )
        
        return try await createUserProfile(newUser)
    }
    
    // Get current user endpoints helper
    var currentUserEndpoints: UserEndpoints? {
        return APIEndpoints.forCurrentUser()
    }
    
    // Fetch assigned coach if user has one
    func fetchAssignedCoach() async throws -> Coach? {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        
        let user = try await syncCurrentUser()
        
        // Use coachUUID computed property instead of coachId directly
        if let coachUUID = user.coachUUID {
            return try await fetchCoach(coachId: coachUUID)
        }
        
        return nil
    }
}

// MARK: - Mock Repository for Testing

class MockUserRepository: UserRepositoryProtocol {
    var shouldFail = false
    var mockUser: APIUser?
    var mockCoach: Coach?
    
    func fetchUserProfile(firebaseUID: String) async throws -> APIUser? {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return mockUser
    }
    
    func createUserProfile(_ user: APIUser) async throws -> APIUser {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return user
    }
    
    func updateUserProfile(_ user: UserUpdateRequest) async throws -> APIUser {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return mockUser ?? APIUser(firebaseUID: "mock", email: "mock@test.com", displayName: "Mock User")
    }
    
    func fetchCoach(coachId: UUID) async throws -> Coach {
        if shouldFail { throw APIError.notFound }
        
        // Create a mock coach with proper initialization
        return mockCoach ?? Coach(
            id: coachId,
            firebaseUID: "coach123",
            displayName: "Coach Test",
            email: "coach@test.com",
            specialization: "HYROX",
            bio: "Coach de test spécialisé HYROX avec plus de 5 ans d'expérience",
            createdAt: Date(),
            athleteCount: 15,
            totalWorkouts: 250,
            averageWorkoutDuration: 45 * 60 // 45 minutes
        )
    }
} 
