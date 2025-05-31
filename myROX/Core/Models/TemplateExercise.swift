import SwiftData
import Foundation

@Model
final class TemplateExercise {
    var id: UUID
    var exerciseName: String
    var targetDistance: Double?
    var targetRepetitions: Int?
    var order: Int = 0
    
    @Relationship(inverse: \WorkoutTemplate.exercises)
    var template: WorkoutTemplate?
    
    init(exerciseName: String, targetDistance: Double? = nil, targetRepetitions: Int? = nil, order: Int = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.targetDistance = targetDistance
        self.targetRepetitions = targetRepetitions
        self.order = order
    }
}

extension TemplateExercise {
    var displayName: String {
        var components: [String] = [exerciseName]
        
        if let distance = targetDistance, distance > 0 {
            components.append("\(Int(distance))m")
        }
        
        if let reps = targetRepetitions, reps > 0 {
            components.append("\(reps) reps")
        }
        
        return components.joined(separator: " : ")
    }
    
    var shortDisplayName: String {
        var components: [String] = []
        
        if let distance = targetDistance, distance > 0 {
            components.append("\(Int(distance))m")
        }
        
        if let reps = targetRepetitions, reps > 0 {
            components.append("\(reps)")
        }
        
        return components.joined(separator: " / ")
    }
} 