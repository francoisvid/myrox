import Foundation

enum APIEndpoints {
    
    // MARK: - Health Check
    case health
    
    // MARK: - User Management (Firebase UID based)
    case userProfile(firebaseUID: String)
    case createUser
    case updateUser(firebaseUID: String)
    
    // MARK: - Coach Info (Read-only - relation créée côté web)
    case coach(id: UUID)
    
    // MARK: - Templates (Firebase UID based)
    case personalTemplates(firebaseUID: String)      // Créés par l'athlete
    case assignedTemplates(firebaseUID: String)      // Assignés par le coach (web)
    case createPersonalTemplate(firebaseUID: String)
    case updatePersonalTemplate(firebaseUID: String, templateId: UUID)
    case deletePersonalTemplate(firebaseUID: String, templateId: UUID)
    
    // MARK: - Workouts (Firebase UID based)
    case workouts(firebaseUID: String)
    case createWorkout(firebaseUID: String)
    case updateWorkout(firebaseUID: String, workoutId: UUID)
    case deleteWorkout(firebaseUID: String, workoutId: UUID)
    
    // MARK: - Stats (Firebase UID based)
    case personalStats(firebaseUID: String)
    case personalBests(firebaseUID: String)
    case createPersonalBest(firebaseUID: String)
    case updatePersonalBest(firebaseUID: String, personalBestId: String)
    case deletePersonalBest(firebaseUID: String, personalBestId: String)
    
    // MARK: - Exercises (Global catalog)
    case exercises
    case exercise(id: UUID)
    
    var path: String {
        switch self {
        // Health
        case .health:
            return "/health"
            
        // User Management
        case .userProfile(let firebaseUID):
            return "/users/firebase/\(firebaseUID)"
        case .createUser:
            return "/users"
        case .updateUser(let firebaseUID):
            return "/users/firebase/\(firebaseUID)"
            
        // Coach Info (Read-only)
        case .coach(let id):
            return "/coaches/\(id.uuidString.lowercased())"
            
        // Templates
        case .personalTemplates(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/personal-templates"
        case .assignedTemplates(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/assigned-templates"
        case .createPersonalTemplate(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/personal-templates"
        case .updatePersonalTemplate(let firebaseUID, let templateId):
            return "/users/firebase/\(firebaseUID)/personal-templates/\(templateId.uuidString.lowercased())"
        case .deletePersonalTemplate(let firebaseUID, let templateId):
            return "/users/firebase/\(firebaseUID)/personal-templates/\(templateId.uuidString.lowercased())"
            
        // Workouts
        case .workouts(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/workouts"
        case .createWorkout(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/workouts"
        case .updateWorkout(let firebaseUID, let workoutId):
            return "/users/firebase/\(firebaseUID)/workouts/\(workoutId.uuidString.lowercased())"
        case .deleteWorkout(let firebaseUID, let workoutId):
            return "/users/firebase/\(firebaseUID)/workouts/\(workoutId.uuidString.lowercased())"
            
        // Stats
        case .personalStats(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/stats"
        case .personalBests(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/personal-bests"
        case .createPersonalBest(let firebaseUID):
            return "/users/firebase/\(firebaseUID)/personal-bests"
        case .updatePersonalBest(let firebaseUID, let personalBestId):
            return "/users/firebase/\(firebaseUID)/personal-bests/\(personalBestId)"
        case .deletePersonalBest(let firebaseUID, let personalBestId):
            return "/users/firebase/\(firebaseUID)/personal-bests/\(personalBestId)"
            
        // Exercises
        case .exercises:
            return "/exercises"
        case .exercise(let id):
            return "/exercises/\(id.uuidString.lowercased())"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .createUser, .createPersonalTemplate, .createWorkout, .createPersonalBest:
            return .POST
        case .updateUser, .updatePersonalTemplate, .updateWorkout, .updatePersonalBest:
            return .PUT
        case .deletePersonalTemplate, .deleteWorkout, .deletePersonalBest:
            return .DELETE
        default:
            return .GET
        }
    }
}

// MARK: - Convenience Extensions

extension APIEndpoints {
    
    // Auto-generate endpoints using current user's Firebase UID
    static func forCurrentUser() -> UserEndpoints? {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            return nil
        }
        return UserEndpoints(firebaseUID: currentUID)
    }
}

// MARK: - User-specific endpoints builder

struct UserEndpoints {
    let firebaseUID: String
    
    var profile: APIEndpoints { .userProfile(firebaseUID: firebaseUID) }
    var personalTemplates: APIEndpoints { .personalTemplates(firebaseUID: firebaseUID) }
    var assignedTemplates: APIEndpoints { .assignedTemplates(firebaseUID: firebaseUID) }
    var workouts: APIEndpoints { .workouts(firebaseUID: firebaseUID) }
    var personalStats: APIEndpoints { .personalStats(firebaseUID: firebaseUID) }
    var personalBests: APIEndpoints { .personalBests(firebaseUID: firebaseUID) }
    
    func createPersonalTemplate() -> APIEndpoints {
        .createPersonalTemplate(firebaseUID: firebaseUID)
    }
    
    func updatePersonalTemplate(templateId: UUID) -> APIEndpoints {
        .updatePersonalTemplate(firebaseUID: firebaseUID, templateId: templateId)
    }
    
    func deletePersonalTemplate(templateId: UUID) -> APIEndpoints {
        .deletePersonalTemplate(firebaseUID: firebaseUID, templateId: templateId)
    }
    
    func createWorkout() -> APIEndpoints {
        .createWorkout(firebaseUID: firebaseUID)
    }
    
    func updateWorkout(workoutId: UUID) -> APIEndpoints {
        .updateWorkout(firebaseUID: firebaseUID, workoutId: workoutId)
    }
    
    func deleteWorkout(workoutId: UUID) -> APIEndpoints {
        .deleteWorkout(firebaseUID: firebaseUID, workoutId: workoutId)
    }
    
    func createPersonalBest() -> APIEndpoints {
        .createPersonalBest(firebaseUID: firebaseUID)
    }
    
    func updatePersonalBest(personalBestId: String) -> APIEndpoints {
        .updatePersonalBest(firebaseUID: firebaseUID, personalBestId: personalBestId)
    }
    
    func deletePersonalBest(personalBestId: String) -> APIEndpoints {
        .deletePersonalBest(firebaseUID: firebaseUID, personalBestId: personalBestId)
    }
}

// Need to import FirebaseAuth for the convenience extension
import FirebaseAuth 