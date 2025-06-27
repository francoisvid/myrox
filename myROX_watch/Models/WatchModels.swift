import Foundation

// Modèles légers pour la Watch
struct WatchTemplateExercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let order: Int
    let targetDistance: Double?
    let targetRepetitions: Int?
    let targetDuration: TimeInterval?
    
    init(name: String, order: Int, targetDistance: Double? = nil, targetRepetitions: Int? = nil, targetDuration: TimeInterval? = nil) {
        self.name = name
        self.order = order
        self.targetDistance = targetDistance
        self.targetRepetitions = targetRepetitions
        self.targetDuration = targetDuration
    }
}

struct WatchTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let exercises: [String] // Compatibilité
    let exercisesData: [WatchTemplateExercise] // Nouveau format avec paramètres
    let rounds: Int
    
    init(id: UUID, name: String, exercises: [String], rounds: Int, exercisesData: [WatchTemplateExercise] = []) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.exercisesData = exercisesData
        self.rounds = rounds
    }
    
    // Propriété calculée pour utiliser les nouvelles données ou fallback
    var templateExercises: [WatchTemplateExercise] {
        if !exercisesData.isEmpty {
            return exercisesData.sorted(by: { $0.order < $1.order })
        } else {
            return exercises.enumerated().map { index, name in
                WatchTemplateExercise(name: name, order: index)
            }
        }
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
    var targetDistance: Double? // Ajout des objectifs
    var targetRepetitions: Int? // Ajout des objectifs
    var targetDuration: TimeInterval? // durée cible en secondes
    var heartRatePoints: [(value: Int, timestamp: Date)] = []
    var isCompleted: Bool = false
    var round: Int = 1
    var order: Int = 0
    
    // Constructeur mis à jour
    init(name: String, round: Int = 1, order: Int = 0, targetDistance: Double? = nil, targetRepetitions: Int? = nil, targetDuration: TimeInterval? = nil) {
        self.name = name
        self.round = round
        self.order = order
        self.targetDistance = targetDistance
        self.targetRepetitions = targetRepetitions
        self.targetDuration = targetDuration
    }
    
    // Helper pour générer l'exerciseType comme sur iOS
    var personalBestExerciseType: String {
        // Nettoyer le nom de l'exercice (enlever espaces, mettre en minuscules) - IDENTIQUE À iOS
        let cleanName = name.lowercased().replacingOccurrences(of: " ", with: "")
        
        let result: String
        
        // Priorité: distance > reps > timeOnly - IDENTIQUE À iOS
        if let distance = targetDistance, distance > 0 {
            let roundedDistance = Int(distance)
            result = "\(cleanName)_\(roundedDistance)m"
        } else if let reps = targetRepetitions, reps > 0 {
            result = "\(cleanName)_\(reps)reps"
        } else if let targetTime = targetDuration, targetTime > 0 {
            result = "\(cleanName)_\(Int(targetTime))sec"
        } else {
            result = "\(cleanName)_timeonly"
        }
        
        // 🐛 DEBUG: Log pour vérifier la génération de clé
        print("🔑 Watch personalBestExerciseType:")
        print("   - Nom original: '\(name)'")
        print("   - Nom nettoyé: '\(cleanName)'")
        print("   - Distance: \(targetDistance ?? 0)")
        print("   - Répétitions: \(targetRepetitions ?? 0)")
        print("   - Clé générée: '\(result)'")
        
        return result
    }
}

// Personal Best pour la Watch
struct WatchPersonalBest: Identifiable, Codable {
    let id = UUID()
    let exerciseType: String
    let value: Double // TimeInterval en secondes
    let achievedAt: Date
    
    init(exerciseType: String, value: Double, achievedAt: Date) {
        self.exerciseType = exerciseType
        self.value = value
        self.achievedAt = achievedAt
    }
}
