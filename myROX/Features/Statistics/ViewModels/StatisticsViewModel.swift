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
private let workoutRepository: WorkoutRepository
private let personalBestRepository: PersonalBestRepository
private var cancellables = Set<AnyCancellable>()
    
    // Cache des workouts
    @Published var workouts: [Workout] = []
    
    // MARK: - Init
    init(modelContext: ModelContext) {
    self.modelContext = modelContext
    self.workoutRepository = WorkoutRepository(modelContext: modelContext)
    self.personalBestRepository = PersonalBestRepository(modelContext: modelContext)
        
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
            let allWorkouts = try modelContext.fetch(descriptor)
            print("📊 DEBUG loadWorkouts - Total workouts en local: \(allWorkouts.count)")
            
            for (index, workout) in allWorkouts.enumerated() {
                print("   [\(index)] ID: \(workout.id)")
                print("       - Template: \(workout.templateName ?? "N/A")")
                print("       - StartedAt: \(workout.startedAt)")
                print("       - CompletedAt: \(workout.completedAt?.description ?? "NIL")")
                print("       - Duration: \(workout.totalDuration)")
                print("       - Exercises: \(workout.performances.count)")
            }
            
            workouts = allWorkouts.filter { $0.completedAt != nil }
            print("📊 DEBUG loadWorkouts - Workouts complétés: \(workouts.count)")
            
            recompute()
        } catch {
            print("Erreur chargement workouts: \(error)")
            workouts = []
        }
    }
    
    /// Synchronisation complète : API → Local avec détection des suppressions
    func forceFullSync() async {
        do {
            // 1. Récupérer tous les workouts depuis l'API
            let apiWorkouts = try await workoutRepository.fetchWorkouts()
            let apiWorkoutIds = Set(apiWorkouts.map { $0.uuid })
            
            // 2. Récupérer les workouts locaux
            let localWorkouts = getCachedWorkouts()
            
            // 3. Supprimer les workouts locaux qui n'existent plus dans l'API
            for localWorkout in localWorkouts {
                if !apiWorkoutIds.contains(localWorkout.id) {
                    print("🗑️ Suppression locale workout inexistant dans l'API: \(localWorkout.id)")
                    modelContext.delete(localWorkout)
                }
            }
            
                    // 4. Synchroniser normalement (ajouts/mises à jour)
        try await workoutRepository.syncWorkoutsWithCache()
        
        // 5. Synchroniser les Personal Bests
        try await personalBestRepository.syncPersonalBestsWithCache()
        
        // 6. Recharger les données locales
        loadWorkouts()
        
        print("✅ Synchronisation complète terminée (workouts + Personal Bests)")
            
        } catch {
            print("❌ Erreur synchronisation complète: \(error)")
        }
    }
    
    private func getCachedWorkouts() -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur récupération workouts locaux: \(error)")
            return []
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
    func deleteWorkout(_ workout: Workout) async throws {
        do {
            // 1. Supprimer côté API d'abord
            try await workoutRepository.deleteWorkout(workoutId: workout.id)
            print("✅ Workout supprimé côté API: \(workout.id)")
            
            // 2. Supprimer localement
            modelContext.delete(workout)
            try modelContext.save()
            print("✅ Workout supprimé localement: \(workout.id)")
            
            // 3. Synchroniser avec la montre
            WatchConnectivityService.shared.sendWorkoutDeleted(workout.id)
            WatchConnectivityService.shared.sendWorkoutCount()
            
                    // 4. Synchroniser les Personal Bests (recalculés par l'API)
        try await personalBestRepository.syncPersonalBestsWithCache()
        print("✅ Personal Bests synchronisés après suppression")
        
        // 5. Recharger les données
        loadWorkouts()
        
    } catch {
        print("❌ Erreur suppression workout: \(error)")
        // En cas d'erreur API, on ne supprime pas localement
        // L'utilisateur sera informé de l'erreur
        throw error
    }
    }
    
    func deleteAllWorkouts() async throws {
        do {
            // 1. Supprimer tous les workouts côté API
            for workout in workouts {
                try await workoutRepository.deleteWorkout(workoutId: workout.id)
            }
            print("✅ Tous les workouts supprimés côté API")
            
            // 2. Supprimer tous les workouts localement
            for workout in workouts {
                modelContext.delete(workout)
            }
            try modelContext.save()
            print("✅ Tous les workouts supprimés localement")
            
            // 3. Synchroniser avec la montre
            let workoutIds = workouts.map { $0.id }
            for workoutId in workoutIds {
                WatchConnectivityService.shared.sendWorkoutDeleted(workoutId)
            }
            WatchConnectivityService.shared.sendWorkoutCount()
            
                    // 4. Synchroniser les Personal Bests (recalculés par l'API)
        try await personalBestRepository.syncPersonalBestsWithCache()
        print("✅ Personal Bests synchronisés après suppression de tous les workouts")
        
        // 5. Recharger les données
        loadWorkouts()
        
    } catch {
        print("❌ Erreur suppression de tous les workouts: \(error)")
        throw error
    }
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
