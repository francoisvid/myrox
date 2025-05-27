import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var exerciseNames: [String] = []
    var rounds: Int = 1
    
    init(name: String, rounds: Int = 1) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.rounds = rounds
    }
}
