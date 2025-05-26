import SwiftData
import Foundation

@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: String
    var hasDistance: Bool
    var hasRepetitions: Bool
    var standardDistance: Double?
    var standardRepetitions: Int?
    
    init(name: String, category: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.hasDistance = false
        self.hasRepetitions = false
    }
}
