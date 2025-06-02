import SwiftUI
import SwiftData
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var selectedPeriodIndex: Int = 0
    @Published var selectedViewMode: StatisticsViewMode = .detailed
    
    // MARK: - Outputs
    @Published private(set) var personalBests: [String: WorkoutExercise] = [:]
    @Published private(set) var exerciseGroups: [String: [WorkoutExercise]] = [:]
    @Published private(set) var chartData: [(Date, TimeInterval)] = []
    @Published private(set) var totalWorkouts: Int = 0
    @Published private(set) var totalTime: TimeInterval = 0
    @Published private(set) var totalDistance: Double = 0
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // Cache des workouts
    @Published var workouts: [Workout] = []
    
    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Observer les changements de période et mode d'affichage
        Publishers.CombineLatest($selectedPeriodIndex, $selectedViewMode)
            .sink { [weak self] _, _ in
                self?.updateChart()
                self?.groupExercises()
            }
            .store(in: &cancellables)
        
        loadWorkouts()
    }
    
    // MARK: - Data Loading
    func loadWorkouts() {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            workouts = try modelContext.fetch(descriptor)
                .filter { $0.completedAt != nil }
            recompute()
        } catch {
            print("Erreur chargement workouts: \(error)")
            workouts = []
        }
    }
    
    // MARK: - Computations
    private func recompute() {
        computePersonalBests()
        groupExercises()
        updateChart()
        updateTotals()
    }
    
    private func computePersonalBests() {
        var bests: [String: WorkoutExercise] = [:]
        
        for workout in workouts {
            for exercise in workout.performances {
                guard exercise.duration > 0 else { continue }
                
                let key = exercise.statisticsKey
                
                if let current = bests[key] {
                    if exercise.duration < current.duration {
                        bests[key] = exercise
                    }
                } else {
                    bests[key] = exercise
                }
            }
        }
        
        personalBests = bests
    }
    
    private func groupExercises() {
        var groups: [String: [WorkoutExercise]] = [:]
        
        for workout in workouts {
            for exercise in workout.performances {
                let key = selectedViewMode == .detailed ? exercise.statisticsKey : exercise.exerciseName
                
                if groups[key] == nil {
                    groups[key] = []
                }
                groups[key]?.append(exercise)
            }
        }
        
        // Trier chaque groupe par date (plus récent en premier)
        for (key, exercises) in groups {
            groups[key] = exercises.sorted { first, second in
                guard let firstDate = first.workout?.completedAt,
                      let secondDate = second.workout?.completedAt else {
                    return false
                }
                return firstDate > secondDate
            }
        }
        
        exerciseGroups = groups
    }
    
    private func updateTotals() {
        totalWorkouts = workouts.count
        totalTime = workouts.reduce(0) { $0 + $1.totalDuration }
        totalDistance = workouts.reduce(0) { $0 + $1.totalDistance }
    }
    
    private func updateChart() {
        let months = [3, 6, 12, 24][selectedPeriodIndex]
        let cutoffDate = Calendar.current.date(
            byAdding: .month,
            value: -months,
            to: Date()
        ) ?? Date()
        
        chartData = workouts
            .filter { workout in
                guard let date = workout.completedAt else { return false }
                return date >= cutoffDate
            }
            .compactMap { workout in
                guard let date = workout.completedAt else { return nil }
                return (date, workout.totalDuration)
            }
            .sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Actions
    func deleteWorkout(_ workout: Workout) {
        // Sauvegarder l'ID avant la suppression
        let workoutId = workout.id
        
        // Supprimer le workout
        modelContext.delete(workout)
        try? modelContext.save()
        
        // Synchroniser avec la montre
        WatchConnectivityService.shared.sendWorkoutDeleted(workoutId)
        WatchConnectivityService.shared.sendWorkoutCount()
        
        // Recharger les données
        loadWorkouts()
    }
    
    func deleteAllWorkouts() {
        // Sauvegarder les IDs avant la suppression
        let workoutIds = workouts.map { $0.id }
        
        // Supprimer tous les workouts
        for workout in workouts {
            modelContext.delete(workout)
        }
        try? modelContext.save()
        
        // Synchroniser avec la montre
        for workoutId in workoutIds {
            WatchConnectivityService.shared.sendWorkoutDeleted(workoutId)
        }
        WatchConnectivityService.shared.sendWorkoutCount()
        
        // Recharger les données
        loadWorkouts()
    }
    
    // MARK: - Helpers
    func exerciseHistory(for key: String) -> [(WorkoutExercise, Date)] {
        if selectedViewMode == .combined {
            // En mode combiné, combiner toutes les variantes de l'exercice
            let allVariants = exerciseGroups.keys.filter { exerciseKey in
                let exerciseName = exerciseKey.components(separatedBy: "_").first ?? exerciseKey
                return exerciseName == key
            }
            
            var combinedHistory: [(WorkoutExercise, Date)] = []
            for variant in allVariants {
                if let exercises = exerciseGroups[variant] {
                    let variantHistory = exercises.compactMap { exercise -> (WorkoutExercise, Date)? in
                        guard let date = exercise.workout?.completedAt else { return nil }
                        return (exercise, date)
                    }
                    combinedHistory.append(contentsOf: variantHistory)
                }
            }
            
            // Trier par date (plus récent en premier)
            return combinedHistory.sorted { $0.1 > $1.1 }
        } else {
            // En mode détaillé, utiliser la clé directement
            guard let exercises = exerciseGroups[key] else { return [] }
            
            return exercises.compactMap { exercise -> (WorkoutExercise, Date)? in
                guard let date = exercise.workout?.completedAt else { return nil }
                return (exercise, date)
            }
        }
    }
    
    func exerciseVariants(for exerciseName: String) -> [String] {
        let variants = exerciseGroups.keys.filter { key in
            if selectedViewMode == .detailed {
                return key.hasPrefix(exerciseName + "_") || key == exerciseName + "_timeOnly"
            } else {
                return key == exerciseName
            }
        }
        
        return variants.sorted()
    }
    
    func comparison() -> (previous: Workout?, latest: Workout?) {
        guard workouts.count >= 2 else {
            return (workouts.first, nil)
        }
        return (workouts[1], workouts[0])
    }
    
    var uniqueExerciseKeys: [String] {
        let keys = Array(exerciseGroups.keys)
        
        if selectedViewMode == .combined {
            // Mode combiné : extraire les noms d'exercice des clés et maintenir l'ordre HYROX
            let exerciseNames = Set(keys.map { key in
                key.components(separatedBy: "_").first ?? key
            })
            
            let standardOrder = [
                "SkiErg", "Sled Push", "Sled Pull", "Burpees Broad Jump",
                "RowErg", "Farmers Carry", "Sandbag Lunges", "Wall Balls", "Running"
            ]
            
            return standardOrder.filter { exerciseNames.contains($0) } +
                   exerciseNames.subtracting(standardOrder).sorted()
        } else {
            // Mode détaillé : trier intelligemment les clés en préservant l'ordre HYROX
            return sortedDetailedKeys(keys)
        }
    }
    
    private func sortedDetailedKeys(_ keys: [String]) -> [String] {
        // Grouper par exercice et trier
        let grouped = Dictionary(grouping: keys) { key in
            key.components(separatedBy: "_").first ?? key
        }
        
        let standardOrder = [
            "SkiErg", "Sled Push", "Sled Pull", "Burpees Broad Jump",
            "RowErg", "Farmers Carry", "Sandbag Lunges", "Wall Balls", "Running"
        ]
        
        var result: [String] = []
        
        // Ajouter dans l'ordre standard HYROX
        for exerciseName in standardOrder {
            if let variants = grouped[exerciseName] {
                // Trier les variantes par paramètres (distance puis répétitions)
                let sortedVariants = variants.sorted { key1, key2 in
                    let params1 = extractParameters(from: key1)
                    let params2 = extractParameters(from: key2)
                    
                    // Prioriser "temps seulement" en dernier
                    if key1.hasSuffix("_timeOnly") && !key2.hasSuffix("_timeOnly") {
                        return false
                    }
                    if !key1.hasSuffix("_timeOnly") && key2.hasSuffix("_timeOnly") {
                        return true
                    }
                    
                    // Trier par distance d'abord
                    if params1.distance != params2.distance {
                        return params1.distance < params2.distance
                    }
                    
                    // Puis par répétitions
                    return params1.repetitions < params2.repetitions
                }
                result.append(contentsOf: sortedVariants)
            }
        }
        
        // Ajouter les exercices non-standard à la fin
        let remainingExercises = Set(grouped.keys).subtracting(standardOrder)
        for exerciseName in remainingExercises.sorted() {
            if let variants = grouped[exerciseName] {
                let sortedVariants = variants.sorted { key1, key2 in
                    let params1 = extractParameters(from: key1)
                    let params2 = extractParameters(from: key2)
                    
                    if params1.distance != params2.distance {
                        return params1.distance < params2.distance
                    }
                    return params1.repetitions < params2.repetitions
                }
                result.append(contentsOf: sortedVariants)
            }
        }
        
        return result
    }
    
    private func extractParameters(from key: String) -> (distance: Double, repetitions: Int) {
        let components = key.components(separatedBy: "_")
        var distance: Double = 0
        var repetitions: Int = 0
        
        for component in components {
            if component.hasSuffix("m"), let value = Double(String(component.dropLast())) {
                distance = value
            } else if component.hasSuffix("reps"), let value = Int(String(component.dropLast(4))) {
                repetitions = value
            }
        }
        
        return (distance, repetitions)
    }
    
    func personalBest(for key: String) -> WorkoutExercise? {
        if selectedViewMode == .combined {
            // En mode combiné, trouver le meilleur temps parmi toutes les variantes
            let allVariants = exerciseGroups.keys.filter { exerciseKey in
                let exerciseName = exerciseKey.components(separatedBy: "_").first ?? exerciseKey
                return exerciseName == key
            }
            
            var best: WorkoutExercise?
            for variant in allVariants {
                if let variantBest = personalBests[variant] {
                    if let currentBest = best {
                        if variantBest.duration < currentBest.duration {
                            best = variantBest
                        }
                    } else {
                        best = variantBest
                    }
                }
            }
            return best
        } else {
            // En mode détaillé, utiliser le record pour cette variante spécifique
            return personalBests[key]
        }
    }
}

// MARK: - Statistics View Mode

enum StatisticsViewMode: String, CaseIterable {
    case detailed = "detailed"
    case combined = "combined"
    
    var displayName: String {
        switch self {
        case .detailed:
            return "Détaillé"
        case .combined:
            return "Combiné"
        }
    }
    
    var description: String {
        switch self {
        case .detailed:
            return "Voir chaque variante séparément"
        case .combined:
            return "Grouper par type d'exercice"
        }
    }
}
