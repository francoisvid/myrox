import Foundation
import FirebaseAuth

// MARK: - API Service

/// Service principal pour les appels API
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
    
    // MARK: - Generic Request Methods
    
    /// Requête avec body
    func request<T: Codable, B: Codable>(
        _ endpoint: APIEndpoints,
        method: HTTPMethod? = nil,
        body: B,
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = (method ?? endpoint.method).rawValue
        request.timeoutInterval = 30
        
        // Headers communs
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Authentification Firebase
        if let firebaseUser = Auth.auth().currentUser {
            request.setValue(firebaseUser.uid, forHTTPHeaderField: "x-firebase-uid")
            
            if let email = firebaseUser.email {
                request.setValue(email, forHTTPHeaderField: "x-firebase-email")
            }
        }
        
        // Encoder le body
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        
        return try await performRequest(request, responseType: responseType)
    }
    
    /// Requête sans body
    func request<T: Codable>(
        _ endpoint: APIEndpoints,
        method: HTTPMethod? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = (method ?? endpoint.method).rawValue
        request.timeoutInterval = 30
        
        // Headers communs
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Authentification Firebase
        if let firebaseUser = Auth.auth().currentUser {
            request.setValue(firebaseUser.uid, forHTTPHeaderField: "x-firebase-uid")
            
            if let email = firebaseUser.email {
                request.setValue(email, forHTTPHeaderField: "x-firebase-email")
            }
        }
        
        return try await performRequest(request, responseType: responseType)
    }
    
    // MARK: - Private Methods
    
    /// Exécution commune des requêtes
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
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            #if DEBUG
            print("📥 API Response: \(httpResponse.statusCode)")
            #endif
            
            // Gestion des codes d'erreur
            switch httpResponse.statusCode {
            case 200...299:
                break // Succès
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
            
            // Debug response
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response Body: \(responseString)")
            }
            #endif
            
            // Décoder la réponse
            do {
                let decoder = JSONDecoder()
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
    
    /// Requête GET
    func get<T: Codable>(_ endpoint: APIEndpoints, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .GET, responseType: responseType)
    }
    
    /// Requête POST
    func post<T: Codable, B: Codable>(_ endpoint: APIEndpoints, body: B, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .POST, body: body, responseType: responseType)
    }
    
    /// Requête PUT
    func put<T: Codable, B: Codable>(_ endpoint: APIEndpoints, body: B, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .PUT, body: body, responseType: responseType)
    }
    
    /// Requête DELETE
    func delete<T: Codable>(_ endpoint: APIEndpoints, responseType: T.Type) async throws -> T {
        return try await request(endpoint, method: .DELETE, responseType: responseType)
    }
}

// MARK: - Specific API Methods

extension APIService {
    
    /// Vérification de la santé de l'API
    func healthCheck() async throws -> HealthResponse {
        return try await get(.health, responseType: HealthResponse.self)
    }
    
    /// Récupération des exercices
    func fetchExercises() async throws -> [APIExercise] {
        return try await get(.exercises, responseType: [APIExercise].self)
    }
    
    /// Récupération d'un exercice spécifique
    func fetchExercise(id: UUID) async throws -> APIExercise {
        return try await get(.exercise(id: id), responseType: APIExercise.self)
    }
    
    /// Récupération du profil utilisateur
    func fetchUserProfile(firebaseUID: String) async throws -> APIUser {
        return try await get(.userProfile(firebaseUID: firebaseUID), responseType: APIUser.self)
    }
    
    /// Création d'un utilisateur
    func createUser(_ request: CreateUserRequest) async throws -> APIUser {
        return try await post(.createUser, body: request, responseType: APIUser.self)
    }
    
    /// Mise à jour d'un utilisateur
    func updateUser(firebaseUID: String, _ request: UpdateUserRequest) async throws -> APIUser {
        return try await put(.updateUser(firebaseUID: firebaseUID), body: request, responseType: APIUser.self)
    }
    
    /// Récupération des templates personnels
    func fetchPersonalTemplates(firebaseUID: String) async throws -> [APITemplate] {
        return try await get(.personalTemplates(firebaseUID: firebaseUID), responseType: [APITemplate].self)
    }
    
    /// Récupération des templates assignés
    func fetchAssignedTemplates(firebaseUID: String) async throws -> [APITemplate] {
        return try await get(.assignedTemplates(firebaseUID: firebaseUID), responseType: [APITemplate].self)
    }
    
    /// Création d'un template personnel
    func createPersonalTemplate(firebaseUID: String, _ request: CreateTemplateRequest) async throws -> APITemplate {
        return try await post(.createPersonalTemplate(firebaseUID: firebaseUID), body: request, responseType: APITemplate.self)
    }
} 
