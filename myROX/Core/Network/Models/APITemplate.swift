import Foundation

// MARK: - Template Models

/// Modèle représentant un template d'entraînement depuis l'API
struct APITemplate: Codable, Identifiable {
    let id: String               
    let name: String
    let rounds: Int
    let description: String?
    let difficulty: String?
    let estimatedTime: Int?
    let category: String?
    let isPersonal: Bool         
    let isActive: Bool
    let exercises: [APITemplateExercise]
    let userId: String           
    let coachId: String?
    let createdAt: String        
    let updatedAt: String        
    
    // MARK: - Computed Properties
    
    /// UUID généré depuis l'ID string
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    /// UUID du créateur
    var userUUID: UUID {
        return UUID(uuidString: userId) ?? UUID()
    }
    
    /// UUID du coach (si assigné)
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
    
    /// Indique si le template a été assigné par un coach
    var isAssignedByCoach: Bool {
        return !isPersonal && coachUUID != nil
    }
    
    /// Nombre total d'exercices (en tenant compte des rounds)
    var totalExercises: Int {
        return exercises.count * rounds
    }
    
    /// Temps estimé formaté
    var formattedEstimatedTime: String {
        guard let time = estimatedTime else { return "Non défini" }
        if time < 60 {
            return "\(time) min"
        } else {
            let hours = time / 60
            let minutes = time % 60
            return minutes > 0 ? "\(hours)h\(minutes)" : "\(hours)h"
        }
    }
    
    /// Difficulté avec emoji
    var difficultyWithIcon: String {
        switch difficulty?.uppercased() {
        case "BEGINNER":
            return "🟢 Débutant"
        case "INTERMEDIATE":
            return "🟡 Intermédiaire"
        case "ADVANCED":
            return "🟠 Avancé"
        case "EXPERT":
            return "🔴 Expert"
        default:
            return "⚪ Non défini"
        }
    }
}

// MARK: - Template Exercise Models

/// Modèle représentant un exercice dans un template depuis l'API
struct APITemplateExercise: Codable, Identifiable {
    let id: String               
    let exercise: APIExercise    
    let order: Int               
    let sets: Int?               
    let reps: Int?               
    let duration: Int?           
    let distance: Double?        
    let weight: Double?          
    let restTime: Int?           
    let notes: String?           
    let templateId: String       
    let exerciseId: String       
    
    // MARK: - Computed Properties
    
    /// UUID généré depuis l'ID string
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    /// UUID du template parent
    var templateUUID: UUID {
        return UUID(uuidString: templateId) ?? UUID()
    }
    
    /// UUID de l'exercice
    var exerciseUUID: UUID {
        return UUID(uuidString: exerciseId) ?? UUID()
    }
    
    // MARK: - Convenience Properties for iOS compatibility
    
    var targetReps: Int? { reps }
    var targetDistance: Double? { distance }
    var targetDuration: Int? { duration }
    var restDuration: Int? { restTime }
    
    /// Description des paramètres pour l'affichage
    var parametersDescription: String {
        var components: [String] = []
        
        if let distance = distance, distance > 0 {
            components.append("\(Int(distance))m")
        }
        
        if let reps = reps, reps > 0 {
            components.append("\(reps) reps")
        }
        
        if let duration = duration, duration > 0 {
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                components.append(seconds > 0 ? "\(minutes):\(String(format: "%02d", seconds))" : "\(minutes) min")
            } else {
                components.append("\(seconds)s")
            }
        }
        
        if let weight = weight, weight > 0 {
            components.append("\(Int(weight))kg")
        }
        
        return components.isEmpty ? "Temps libre" : components.joined(separator: " • ")
    }
}

// MARK: - Template Response Models

/// Réponse pour la liste des templates
struct TemplateListResponse: Codable {
    let templates: [APITemplate]
    let total: Int
    let page: Int
    let limit: Int
}

// MARK: - Template Extensions

extension APITemplate {
    /// Source du template (personnel ou assigné)
    var source: String {
        return isPersonal ? "Personnel" : "Assigné par coach"
    }
    
    /// Icône selon la source
    var sourceIcon: String {
        return isPersonal ? "person.fill" : "person.2.fill"
    }
    
    /// Catégorie avec emoji
    var categoryWithIcon: String {
        switch category?.uppercased() {
        case "HYROX":
            return "🏆 HYROX"
        case "STRENGTH":
            return "💪 Force"
        case "CARDIO":
            return "❤️ Cardio"
        case "FUNCTIONAL":
            return "🏋️‍♀️ Fonctionnel"
        case "FLEXIBILITY":
            return "🧘‍♀️ Flexibilité"
        case "MIXED":
            return "🔥 Mixte"
        default:
            return "📋 Entraînement"
        }
    }
} 