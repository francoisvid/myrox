import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var rounds: Int = 1
    
    @Relationship(deleteRule: .cascade)
    var exercises: [TemplateExercise] = []
    
    init(name: String, rounds: Int = 1) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.rounds = rounds
    }
    
    // Nouveau constructeur pour préserver l'ID API
    init(id: UUID, name: String, rounds: Int = 1) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.rounds = rounds
    }
}
