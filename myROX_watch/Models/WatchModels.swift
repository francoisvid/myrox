import Foundation

// Modèles légers pour la Watch
struct WatchTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let exercises: [String]
}

struct WatchWorkout: Identifiable {
    let id = UUID()
    var templateId: UUID?
    var templateName: String
    var startedAt: Date
    var exercises: [WatchExercise]
    var totalDuration: TimeInterval = 0
    var totalDistance: Double = 0
    
    var isCompleted: Bool {
        exercises.allSatisfy { $0.isCompleted }
    }
}

struct WatchExercise: Identifiable {
    let id = UUID()
    let name: String
    var duration: TimeInterval = 0
    var distance: Double = 0
    var repetitions: Int = 0
    var heartRatePoints: [(value: Int, timestamp: Date)] = []
    var isCompleted: Bool = false
}
