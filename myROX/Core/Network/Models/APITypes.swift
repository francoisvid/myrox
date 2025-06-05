import Foundation

// MARK: - HTTP Methods

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError
    case serverError(Int)
    case httpError(Int)
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .noData:
            return "Aucune donnée reçue"
        case .invalidResponse:
            return "Réponse invalide"
        case .unauthorized:
            return "Non autorisé - vérifiez votre authentification"
        case .forbidden:
            return "Accès interdit"
        case .notFound:
            return "Ressource non trouvée"
        case .validationError:
            return "Erreur de validation des données"
        case .serverError(let code):
            return "Erreur serveur (code \(code))"
        case .httpError(let code):
            return "Erreur HTTP (code \(code))"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Erreur d'encodage: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        }
    }
}

// MARK: - Common Response Models

struct EmptyResponse: Codable {
    // Pour les réponses vides (DELETE, etc.)
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let version: String?
    let uptime: Int?
    let environment: String?
    let message: String?
    let checks: HealthChecks?
    
    struct HealthChecks: Codable {
        let database: String?
        let responseTime: String?
    }
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

// MARK: - List Response Models

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
}

// MARK: - Utility Extensions

extension ISO8601DateFormatter {
    static let apiFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension Date {
    var apiString: String {
        return ISO8601DateFormatter.apiFormatter.string(from: self)
    }
    
    static func fromAPIString(_ string: String) -> Date? {
        return ISO8601DateFormatter.apiFormatter.date(from: string)
    }
} 