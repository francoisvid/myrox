import SwiftData
import Foundation

@Model
final class WorkoutExercise {
    var id: UUID
    var exerciseName: String // Nom de l'exercice réalisé
    var duration: TimeInterval = 0
    var distance: Double = 0
    var repetitions: Int = 0
    var completedAt: Date?
    var averageHeartRate: Int = 0
    var maxHeartRate: Int = 0
    var round: Int = 1 // Numéro du round
    var order: Int = 0 // Ordre dans le round
    var isPersonalRecord: Bool = false // Indique si c'est un record personnel
    
    @Relationship(inverse: \Workout.performances)
    var workout: Workout?
    
    @Relationship(deleteRule: .cascade)
    var heartRatePoints: [HeartRatePoint] = []
    
    init(exerciseName: String, round: Int = 1, order: Int = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.round = round
        self.order = order
    }
}

// MARK: - Statistics Extensions

extension WorkoutExercise {
    /// Clé unique pour identifier un type d'exercice avec ses paramètres spécifiques
    var statisticsKey: String {
        var key = exerciseName
        
        if distance > 0 {
            key += "_\(Int(distance))m"
        }
        
        if repetitions > 0 {
            key += "_\(repetitions)reps"
        }
        
        // Si aucun paramètre, indiquer que c'est temps seulement
        if distance <= 0 && repetitions <= 0 {
            key += "_timeOnly"
        }
        
        return key
    }
    
    /// Nom d'affichage avec paramètres pour les statistiques
    var displayName: String {
        var components: [String] = [exerciseName]
        
        if distance > 0 {
            components.append("\(Int(distance))m")
        }
        
        if repetitions > 0 {
            components.append("\(repetitions) reps")
        }
        
        if distance <= 0 && repetitions <= 0 {
            components.append("temps seulement")
        }
        
        return components.joined(separator: " : ")
    }
    
    /// Version courte pour l'affichage compact
    var shortDisplayName: String {
        var components: [String] = [exerciseName]
        
        if distance > 0 {
            components.append("\(Int(distance))m")
        }
        
        if repetitions > 0 {
            components.append("\(repetitions)")
        }
        
        return components.joined(separator: " ")
    }
    
    /// Détermine si deux exercices sont du même type (même nom + mêmes paramètres)
    func isSameType(as other: WorkoutExercise) -> Bool {
        return self.statisticsKey == other.statisticsKey
    }
    
    /// Détermine si deux exercices peuvent être comparés (même exercice, paramètres compatibles)
    func isComparableTo(_ other: WorkoutExercise) -> Bool {
        guard exerciseName == other.exerciseName else { return false }
        
        // Même distance (ou les deux sans distance)
        let sameDistance = (distance <= 0 && other.distance <= 0) || 
                          (distance > 0 && other.distance > 0 && abs(distance - other.distance) < 1)
        
        // Même répétitions (ou les deux sans répétitions)
        let sameReps = (repetitions <= 0 && other.repetitions <= 0) || 
                      (repetitions > 0 && other.repetitions > 0 && repetitions == other.repetitions)
        
        return sameDistance && sameReps
    }
}
