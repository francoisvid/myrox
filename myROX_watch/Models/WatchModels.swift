import Foundation

// Modèles légers pour la Watch
struct WatchTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let exercises: [String]
    let rounds: Int // Nombre de rounds dans le template
    
    init(id: UUID, name: String, exercises: [String], rounds: Int) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.rounds = rounds
    }
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
    var round: Int = 1 // Numéro du round
    var order: Int = 0 // Ordre dans le round
}
