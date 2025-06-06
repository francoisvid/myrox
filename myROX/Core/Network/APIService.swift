import Foundation
import FirebaseAuth

// MARK: - API Service

/// Service principal pour les appels API
class APIService {
    static let shared = APIService()
    
    // Configuration automatique local/prod
    private let baseURL: String = {
        #if DEBUG
        return "http://localhost:3001/api/v1"  // Local Fastify
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
        method: HTTPMethod,
        body: B,
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        
        // Headers communs - Ne pas ajouter Content-Type pour DELETE sans body
        if method != .DELETE {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Authentification
        if let auth = Auth.auth().currentUser {
            request.setValue(auth.uid, forHTTPHeaderField: "x-firebase-uid")
            request.setValue(auth.email, forHTTPHeaderField: "x-firebase-email")
        }
        
        // Body
        do {
            let bodyData = try JSONEncoder().encode(body)
            request.httpBody = bodyData
            
            // Debug: afficher le JSON envoyé pour les méthodes PUT/POST
            #if DEBUG
            if method == .PUT || method == .POST {
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("📤 APIService - Body JSON envoyé (\(method.rawValue)):")
                    print(bodyString)
                }
            }
            #endif
            
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
        
        // Headers communs - Ne pas ajouter Content-Type pour DELETE sans body
        let requestMethod = method ?? endpoint.method
        if requestMethod != .DELETE {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
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
            print("🚀 performRequest - Début de la requête")
            let (data, response) = try await session.data(for: request)
            print("📡 performRequest - Données reçues, taille: \(data.count) bytes")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ performRequest - Réponse n'est pas HTTPURLResponse")
                throw APIError.invalidResponse
            }
            
            print("📥 performRequest - Code de statut HTTP: \(httpResponse.statusCode)")
            
            // Debug response AVANT de vérifier les codes d'erreur
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response Body: \(responseString)")
            }
            #endif
            
            // Gestion des codes d'erreur
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ performRequest - Code de succès détecté: \(httpResponse.statusCode)")
                break // Succès
            case 401:
                print("❌ performRequest - Erreur 401")
                throw APIError.unauthorized
            case 403:
                print("❌ performRequest - Erreur 403")
                throw APIError.forbidden
            case 404:
                print("❌ performRequest - Erreur 404")
                throw APIError.notFound
            case 422:
                print("❌ performRequest - Erreur 422")
                throw APIError.validationError
            case 500...599:
                print("❌ performRequest - Erreur serveur: \(httpResponse.statusCode)")
                throw APIError.serverError(httpResponse.statusCode)
            default:
                print("❌ performRequest - Erreur HTTP inconnue: \(httpResponse.statusCode)")
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // Décoder la réponse
            print("🔄 performRequest - Début du décodage en tant que \(T.self)")
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: data)
                print("✅ performRequest - Décodage réussi")
                return result
            } catch {
                print("❌ performRequest - Erreur de décodage: \(error)")
                print("❌ performRequest - Données reçues: \(String(data: data, encoding: .utf8) ?? "Non-UTF8")")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            print("❌ performRequest - APIError capturée: \(error)")
            throw error
        } catch {
            print("❌ performRequest - Erreur réseau: \(error)")
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
    
    // MARK: - Workout Methods
    
    /// Récupération des workouts d'un utilisateur
    func fetchWorkouts(firebaseUID: String, includeIncomplete: Bool = false, limit: Int = 50, offset: Int = 0) async throws -> [APIWorkout] {
        var endpoint = APIEndpoints.workouts(firebaseUID: firebaseUID)
        // Note: Pour les paramètres de requête, on pourrait étendre APIEndpoints pour les gérer
        // Pour l'instant, on utilise l'endpoint de base
        return try await get(endpoint, responseType: [APIWorkout].self)
    }
    
    /// Création d'un workout
    func createWorkout(firebaseUID: String, _ request: CreateWorkoutRequest) async throws -> APIWorkout {
        return try await post(.createWorkout(firebaseUID: firebaseUID), body: request, responseType: APIWorkout.self)
    }
    
    /// Mise à jour d'un workout
    func updateWorkout(firebaseUID: String, workoutId: UUID, _ request: UpdateWorkoutRequest) async throws -> APIWorkout {
        return try await put(.updateWorkout(firebaseUID: firebaseUID, workoutId: workoutId), body: request, responseType: APIWorkout.self)
    }
    
    /// Suppression d'un workout
    func deleteWorkout(firebaseUID: String, workoutId: UUID) async throws {
        struct EmptyResponse: Codable {}
        _ = try await delete(.deleteWorkout(firebaseUID: firebaseUID, workoutId: workoutId), responseType: EmptyResponse.self)
    }
    
    /// Récupération des records personnels
    func fetchPersonalBests(firebaseUID: String) async throws -> [APIPersonalBest] {
        return try await get(.personalBests(firebaseUID: firebaseUID), responseType: [APIPersonalBest].self)
    }
    
    /// Création d'un record personnel
    func createPersonalBest(firebaseUID: String, _ request: CreatePersonalBestRequest) async throws -> APIPersonalBest {
        return try await post(.createPersonalBest(firebaseUID: firebaseUID), body: request, responseType: APIPersonalBest.self)
    }
    
    /// Mise à jour d'un record personnel
    func updatePersonalBest(firebaseUID: String, personalBestId: String, _ request: UpdatePersonalBestRequest) async throws -> APIPersonalBest {
        return try await put(.updatePersonalBest(firebaseUID: firebaseUID, personalBestId: personalBestId), body: request, responseType: APIPersonalBest.self)
    }
    
    /// Suppression d'un record personnel
    func deletePersonalBest(firebaseUID: String, personalBestId: String) async throws {
        struct EmptyResponse: Codable {}
        _ = try await delete(.deletePersonalBest(firebaseUID: firebaseUID, personalBestId: personalBestId), responseType: EmptyResponse.self)
    }
} 
