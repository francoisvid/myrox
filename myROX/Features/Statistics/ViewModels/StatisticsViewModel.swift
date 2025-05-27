import SwiftUI
import SwiftData
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var selectedPeriodIndex: Int = 0
    
    // MARK: - Outputs
    @Published private(set) var personalBests: [String: WorkoutExercise] = [:]
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
        
        // Observer les changements de période
        $selectedPeriodIndex
            .sink { [weak self] _ in
                self?.updateChart()
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
        updateChart()
        updateTotals()
    }
    
    private func computePersonalBests() {
        var bests: [String: WorkoutExercise] = [:]
        
        for workout in workouts {
            for exercise in workout.performances {
                guard exercise.duration > 0 else { continue }
                
                if let current = bests[exercise.exerciseName] {
                    if exercise.duration < current.duration {
                        bests[exercise.exerciseName] = exercise
                    }
                } else {
                    bests[exercise.exerciseName] = exercise
                }
            }
        }
        
        personalBests = bests
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
    func exerciseHistory(for name: String) -> [(WorkoutExercise, Date)] {
        workouts
            .compactMap { workout in
                guard let date = workout.completedAt,
                      let exercise = workout.performances.first(where: { $0.exerciseName == name })
                else { return nil }
                return (exercise, date)
            }
            .sorted { $0.1 > $1.1 }
    }
    
    func comparison() -> (previous: Workout?, latest: Workout?) {
        guard workouts.count >= 2 else {
            return (workouts.first, nil)
        }
        return (workouts[1], workouts[0])
    }
    
    var uniqueExerciseNames: [String] {
        let names = Set<String>(
            workouts.flatMap { workout in
                workout.performances.map { $0.exerciseName }
            }
        )
        
        // Ordre standard HYROX
        let standardOrder = [
            "SkiErg", "Sled Push", "Sled Pull", "Burpees Broad Jump",
            "RowErg", "Farmers Carry", "Sandbag Lunges", "Wall Balls", "Running"
        ]
        
        return standardOrder.filter { names.contains($0) } +
               names.subtracting(standardOrder).sorted()
    }
}
