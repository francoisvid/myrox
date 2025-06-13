import Foundation

// MARK: - Exercise Models

/// Modèle représentant un exercice depuis l'API
struct APIExercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: String
    let equipment: [String]
    let instructions: String
    let isHyroxExercise: Bool
    let videoUrl: String?
    let createdAt: String?     // Optional car pas toujours dans la réponse
    let updatedAt: String?     // Optional car pas toujours dans la réponse
    
    // MARK: - Computed Properties
    
    /// UUID généré depuis l'ID string
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    /// Date de création parsée
    var createdDate: Date {
        guard let createdAt = createdAt else { return Date() }
        return Date.fromAPIString(createdAt) ?? Date()
    }
    
    /// Date de mise à jour parsée
    var updatedDate: Date {
        guard let updatedAt = updatedAt else { return Date() }
        return Date.fromAPIString(updatedAt) ?? Date()
    }
    
    /// Indique si l'exercice a des équipements requis
    var hasEquipment: Bool {
        return !equipment.isEmpty
    }
    
    /// Description courte pour l'affichage
    var shortDescription: String {
        return description.count > 100 
            ? String(description.prefix(100)) + "..."
            : description
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, equipment, instructions, isHyroxExercise, videoUrl, createdAt, updatedAt
    }
}

// MARK: - Exercise List Response

/// Réponse pour la liste des exercices
struct ExerciseListResponse: Codable {
    let exercises: [APIExercise]
    let total: Int
    let page: Int
    let limit: Int
}

// MARK: - Exercise Extensions

extension APIExercise {
    /// Catégorie avec icône pour l'affichage iOS
    var categoryWithIcon: String {
        switch category.uppercased() {
        case "RUNNING":
            return "🏃‍♂️ Course"
        case "STRENGTH":
            return "💪 Force"
        case "FUNCTIONAL":
            return "🏋️‍♀️ Fonctionnel"
        case "CARDIO":
            return "❤️ Cardio"
        case "FLEXIBILITY":
            return "🧘‍♀️ Flexibilité"
        case "HYROX_STATION":
            return "🏆 Station HYROX"
        default:
            return "🔥 \(category)"
        }
    }
    
    /// Badge pour l'affichage (HYROX ou Fonctionnel)
    var badge: String {
        return isHyroxExercise ? "HYROX" : "FONCTIONNEL"
    }
    
    /// Couleur du badge pour l'affichage
    var badgeColor: String {
        return isHyroxExercise ? "yellow" : "blue"
    }
} 