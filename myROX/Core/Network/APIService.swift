import Foundation
import FirebaseAuth

class APIService {
    static let shared = APIService()
    
    // Configuration automatique local/prod
    private let baseURL: String = {
        #if DEBUG
        return "http://localhost:3000/api/v1"  // Local Fastify
        #else
        return "https://myrox.api.vdl-creation.fr/api/v1"  // Production
        #endif
    }()
    
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Generic Request Method
    
    // Request method with body
    func request<T: Codable, B: Codable>(
        _ endpoint: APIEndpoints,
        method: HTTPMethod? = nil,
        body: B,
        responseType: T.Type
    ) async throws -> T {
        
        // Construire l'URL
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = (method ?? endpoint.method).rawValue
        request.timeoutInterval = 30
        
        // Headers communs
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ Authentification simple - Firebase UID
        if let firebaseUser = Auth.auth().currentUser {
            request.setValue(firebaseUser.uid, forHTTPHeaderField: "x-firebase-uid")
            
            // Optionnel : Email pour debug
            if let email = firebaseUser.email {
                request.setValue(email, forHTTPHeaderField: "x-firebase-email")
            }
        }
        
        // Encoder le body
        do {
            let encoder = JSONEncoder()
            // Note: Les dates sont gérées manuellement dans les modèles
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        
        return try await performRequest(request, responseType: responseType)
    }
    
    // Request method without body
    func request<T: Codable>(
        _ endpoint: APIEndpoints,
        method: HTTPMethod? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        // Construire l'URL
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = (method ?? endpoint.method).rawValue
        request.timeoutInterval = 30
        
        // Headers communs
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ Authentification simple - Firebase UID
        if let firebaseUser = Auth.auth().currentUser {
            request.setValue(firebaseUser.uid, forHTTPHeaderField: "x-firebase-uid")
            
            // Optionnel : Email pour debug
            if let email = firebaseUser.email {
                request.setValue(email, forHTTPHeaderField: "x-firebase-email")
            }
        }
        
        return try await performRequest(request, responseType: responseType)
    }
    
    // Common request execution
    private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        
        // Debug logging en développement
        #if DEBUG
        print("🌐 API Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("📋 Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        #endif
        
        // Effectuer la requête
        do {
            let (data, response) = try await session.data(for: request)
            
            // Vérifier la réponse HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            #if DEBUG
            print("📥 API Response: \(httpResponse.statusCode)")
            #endif
            
            // Gestion des codes d'erreur
            switch httpResponse.statusCode {
            case 200...299:
                // Succès - décoder la réponse
                break
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 422:
                throw APIError.validationError
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // Debug response en développement
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response Body: \(responseString)")
            }
            #endif
            
            // Décoder la réponse
            do {
                let decoder = JSONDecoder()
                // Note: Les dates sont gérées manuellement dans les modèles
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Convenience Methods

extension APIService {
    
    // GET request
    func get<T: Codable>(_ endpoint: APIEndpoints, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .GET, responseType: responseType)
    }
    
    // POST request
    func post<T: Codable, B: Codable>(_ endpoint: APIEndpoints, body: B, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .POST, body: body, responseType: responseType)
    }
    
    // PUT request
    func put<T: Codable, B: Codable>(_ endpoint: APIEndpoints, body: B, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .PUT, body: body, responseType: responseType)
    }
    
    // DELETE request
    func delete<T: Codable>(_ endpoint: APIEndpoints, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .DELETE, responseType: responseType)
    }
    
    // Health check
    func healthCheck() async throws -> HealthResponse {
        return try await get(.health, responseType: HealthResponse.self)
    }
    
    // Fetch exercises
    func fetchExercises() async throws -> [APIExercise] {
        return try await get(.exercises, responseType: [APIExercise].self)
    }
}

// MARK: - Health Response Model

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let version: String
    let uptime: Int
    let environment: String
    let message: String
    let checks: HealthChecks?
    
    struct HealthChecks: Codable {
        let database: String
        let responseTime: String
    }
}

// MARK: - HTTP Methods

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError
    case serverError(Int)
    case httpError(Int)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .encodingError(let error):
            return "Erreur d'encodage: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .unauthorized:
            return "Non autorisé - Veuillez vous reconnecter"
        case .forbidden:
            return "Accès interdit"
        case .notFound:
            return "Ressource non trouvée"
        case .validationError:
            return "Données invalides"
        case .serverError(let code):
            return "Erreur serveur (\(code))"
        case .httpError(let code):
            return "Erreur HTTP (\(code))"
        case .custom(let message):
            return message
        }
    }
} 
