import Foundation

// MARK: - User Models

/// Modèle représentant un utilisateur depuis l'API
struct APIUser: Codable, Identifiable {
    let id: String               
    let firebaseUID: String      
    let email: String?
    let displayName: String?
    let coachId: String?         
    let createdAt: String        
    let updatedAt: String        
    
    // MARK: - Computed Properties
    
    /// UUID généré depuis l'ID string
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    /// UUID du coach assigné (si existant)
    var coachUUID: UUID? {
        guard let coachId = coachId, !coachId.isEmpty else { return nil }
        return UUID(uuidString: coachId)
    }
    
    /// Date de création parsée
    var createdDate: Date {
        return Date.fromAPIString(createdAt) ?? Date()
    }
    
    /// Date de mise à jour parsée
    var updatedDate: Date {
        return Date.fromAPIString(updatedAt) ?? Date()
    }
    
    /// Indique si l'utilisateur a un coach assigné
    var hasAssignedCoach: Bool {
        return coachUUID != nil
    }
    
    /// Nom d'affichage ou email par défaut
    var displayText: String {
        return displayName ?? email ?? "Utilisateur"
    }
    
    /// Initiales pour l'avatar
    var initials: String {
        let name = displayName ?? email ?? "U"
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
}

// MARK: - Coach Models

/// Modèle représentant un coach (lecture seule pour iOS)
struct APICoach: Codable, Identifiable {
    let id: String
    let name: String // L'API retourne "name" au lieu de "displayName"
    let email: String?
    let bio: String?
    let certifications: [String]?
    let profilePicture: String?
    let createdAt: String
    let isActive: Bool?
    
    // Statistiques du coach (calculées côté serveur, optionnelles)
    let athleteCount: Int?
    let totalWorkouts: Int?
    let averageWorkoutDuration: Int? // en secondes
    let specialization: String?
    
    // MARK: - Computed Properties
    
    /// UUID généré depuis l'ID string
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    /// Nom d'affichage (pour compatibilité avec l'interface)
    var displayName: String {
        return name
    }
    
    /// Date de création parsée
    var createdDate: Date {
        return Date.fromAPIString(createdAt) ?? Date()
    }
    
    /// Spécialisation avec emoji
    var specializationWithIcon: String {
        guard let specialization = specialization else { return "🏃‍♂️ Coach général" }
        
        switch specialization.lowercased() {
        case "hyrox":
            return "🏆 Coach HYROX"
        case "crossfit":
            return "🏋️‍♂️ Coach CrossFit"
        case "running":
            return "🏃‍♂️ Coach course"
        case "strength":
            return "💪 Coach force"
        case "cardio":
            return "❤️ Coach cardio"
        default:
            return "🏃‍♂️ \(specialization)"
        }
    }
    
    /// Durée moyenne des entraînements formatée
    var formattedAverageWorkoutDuration: String {
        guard let duration = averageWorkoutDuration else { return "Non défini" }
        let minutes = duration / 60
        let seconds = duration % 60
        return seconds > 0 ? "\(minutes):\(String(format: "%02d", seconds))" : "\(minutes) min"
    }
    
    /// Description courte du coach
    var shortBio: String {
        guard let bio = bio else { return "Aucune description" }
        return bio.count > 120 
            ? String(bio.prefix(120)) + "..."
            : bio
    }
}

// MARK: - User Response Models

/// Réponse pour la liste des utilisateurs  
struct UserListResponse: Codable {
    let users: [APIUser]
    let total: Int
    let page: Int
    let limit: Int
}

/// Réponse générique pour l'API
struct APIGenericResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

// MARK: - User Extensions

extension APIUser {
    /// Statut d'entraînement (avec ou sans coach)
    var trainingStatus: String {
        return hasAssignedCoach ? "Suivi par coach" : "Entraînement autonome"
    }
    
    /// Icône du statut
    var statusIcon: String {
        return hasAssignedCoach ? "person.2.fill" : "person.fill"
    }
    
    /// Ancienneté formatée
    var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return "Membre depuis \(formatter.string(from: createdDate))"
    }
} 