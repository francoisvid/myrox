import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    
    var exerciseNames: [String] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
