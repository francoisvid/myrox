import Foundation

// MARK: - APIExercise
struct APIExercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: String
    let equipment: [String]
    let instructions: String
    let isHyroxExercise: Bool
    let videoUrl: String?
    let createdAt: String?     // Optional car pas dans l'endpoint /exercises
    let updatedAt: String?     // Optional car pas dans l'endpoint /exercises
    
    // MARK: - Computed Properties for iOS compatibility
    
    var uuid: UUID {
        return UUID(uuidString: id) ?? UUID()
    }
    
    var createdDate: Date {
        guard let createdAt = createdAt else { return Date() }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
    
    var updatedDate: Date {
        guard let updatedAt = updatedAt else { return Date() }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: updatedAt) ?? Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, equipment, instructions, isHyroxExercise, videoUrl, createdAt, updatedAt
    }
} 