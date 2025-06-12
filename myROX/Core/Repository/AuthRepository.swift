import Foundation
import FirebaseAuth

protocol AuthRepositoryProtocol {
    func useInvitationCode(code: String) async throws -> UseInvitationResponse
}

class AuthRepository: AuthRepositoryProtocol {
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    // MARK: - Invitation Code Management
    
    func useInvitationCode(code: String) async throws -> UseInvitationResponse {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        
        let requestBody = UseInvitationRequest(
            code: code,
            firebaseUID: firebaseUser.uid
        )
        
        return try await apiService.post(.useInvitation, body: requestBody, responseType: UseInvitationResponse.self)
    }
}

// MARK: - Request Models

struct UseInvitationRequest: Codable {
    let code: String
    let firebaseUID: String
}

// MARK: - Response Models

struct UseInvitationResponse: Codable {
    let success: Bool
    let message: String
    let coach: CoachInfo
    
    struct CoachInfo: Codable {
        let id: String
        let displayName: String
        let specialization: String?
    }
}

// MARK: - Mock Repository for Testing

class MockAuthRepository: AuthRepositoryProtocol {
    var shouldFail = false
    var mockResponse: UseInvitationResponse?
    
    func useInvitationCode(code: String) async throws -> UseInvitationResponse {
        if shouldFail {
            throw APIError.forbidden("Code invalide")
        }
        
        return mockResponse ?? UseInvitationResponse(
            success: true,
            message: "Vous êtes maintenant lié au coach Test",
            coach: UseInvitationResponse.CoachInfo(
                id: "test-coach-id",
                displayName: "Coach Test",
                specialization: "HYROX"
            )
        )
    }
} 