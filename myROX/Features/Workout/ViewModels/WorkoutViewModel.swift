import SwiftUI
import SwiftData
import Combine

@MainActor
@Observable
class WorkoutViewModel {
    // MARK: - État UI
    var selectedExercise: WorkoutExercise?
    var isEditingExercise = false
    var showCreateTemplate = false
    
    // MARK: - État Workout
    var activeWorkout: Workout?
    var isWorkoutActive = false
    var elapsedTime: TimeInterval = 0
    var workoutProgress: Double = 0
    
    // MARK: - Timer
    private var timer: Timer?
    private var workoutStartTime: Date?
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    
    // MARK: - Templates
    var templates: [WorkoutTemplate] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTemplates()
    }
    
    // MARK: - Méthode pour charger les templates
    func fetchTemplates() {
        do {
            let descriptor = FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            self.templates = try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors du chargement des templates : \(error)")
            self.templates = []
        }
    }
    
    // MARK: - Workout Actions
    func startWorkout(from template: WorkoutTemplate) {
        let workout = Workout()
        workout.templateID = template.id
        
        // Créer les exercices depuis les noms
        for exerciseName in template.exerciseNames {
            let workoutExercise = WorkoutExercise(exerciseName: exerciseName)
            workout.performances.append(workoutExercise)
        }
        
        activeWorkout = workout
        isWorkoutActive = true
        workoutStartTime = Date()
        
        modelContext.insert(workout)
        startTimer()
        if let workout = activeWorkout {
             WatchConnectivityService.shared.sendActiveWorkout(workout)
         }
        print("startWorkout: performances créées =", workout.performances.count)
    }

    
    func endWorkout() {
        guard let workout = activeWorkout else { return }
        
        // Finaliser le workout
        workout.completedAt = Date()
        workout.totalDuration = elapsedTime
        // Assurez-vous que workout.performances.map { $0.distance } retourne des Doubles pour la somme
        workout.totalDistance = workout.performances.reduce(0.0) { $0 + $1.distance }
        
        // Sauvegarder
        do {
            try modelContext.save()
            WatchConnectivityService.shared.sendWorkoutCount()
        } catch {
            print("Erreur lors de la sauvegarde du workout : \(error)")
        }
        
        // Réinitialiser l'état
        stopTimer()
        activeWorkout = nil
        isWorkoutActive = false
        elapsedTime = 0
        workoutProgress = 0
        workoutStartTime = nil
    }
    
    func completeExercise(_ exercise: WorkoutExercise, duration: TimeInterval, distance: Double, repetitions: Int) {
        exercise.duration = duration
        exercise.distance = distance
        exercise.repetitions = repetitions
        exercise.completedAt = Date()
        
        // Mettre à jour la progression
        updateProgress()
        
        // Sauvegarder
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde de l'exercice : \(error)")
        }
    }
    
    // MARK: - Template Management
    func createTemplate(name: String, exerciseNames: [String]) {
        let template = WorkoutTemplate(name: name)
        template.exerciseNames = exerciseNames
        
        modelContext.insert(template)
        do {
            try modelContext.save()
            fetchTemplates()
            WatchConnectivityService.shared.sendTemplates()
        } catch {
            print("Erreur lors de la création du template : \(error)")
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        do {
            try modelContext.save()
            fetchTemplates() // Recharger les templates après la suppression
        } catch {
            print("Erreur lors de la suppression du template : \(error)")
        }
    }
    
    func deleteAllTemplates() {
        for template in templates {
            modelContext.delete(template)
        }
        do {
            try modelContext.save()
            fetchTemplates() // Recharger les templates après la suppression de tous
        } catch {
            print("Erreur lors de la suppression de tous les templates : \(error)")
        }
    }
    
    // MARK: - UI Helpers
    func selectExercise(_ exercise: WorkoutExercise) {
        selectedExercise = exercise
        isEditingExercise = true
    }
    
    func isNextExercise(_ exercise: WorkoutExercise) -> Bool {
        guard let workout = activeWorkout else { return false }
        return workout.performances.first { $0.completedAt == nil } == exercise
    }
    
    // MARK: - Private Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        guard let startTime = workoutStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }
    
    private func updateProgress() {
        guard let workout = activeWorkout else { return }
        let total = workout.performances.count
        let completed = workout.performances.filter { $0.completedAt != nil }.count
        workoutProgress = total > 0 ? (Double(completed) / Double(total)) * 100 : 0
    }
}
