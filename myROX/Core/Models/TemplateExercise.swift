import SwiftData
import Foundation

@Model
final class TemplateExercise {
    var id: UUID
    var exerciseName: String
    var targetDistance: Double?
    var targetRepetitions: Int?
    var targetDuration: TimeInterval?
    var order: Int = 1
    
    @Relationship(inverse: \WorkoutTemplate.exercises)
    var template: WorkoutTemplate?
    
    init(exerciseName: String, targetDistance: Double? = nil, targetRepetitions: Int? = nil, targetDuration: TimeInterval? = nil, order: Int = 1) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.targetDistance = targetDistance
        self.targetRepetitions = targetRepetitions
        self.targetDuration = targetDuration
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
        
        if let time = targetDuration, time > 0 {
            components.append(time.formatted)
        } else if targetDistance == nil && targetRepetitions == nil {
            components.append("temps")
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
        
        if let time = targetDuration, time > 0 {
            components.append(time.formatted)
        } else if targetDistance == nil && targetRepetitions == nil {
            components.append("t")
        }
        
        return components.joined(separator: " / ")
    }
} 