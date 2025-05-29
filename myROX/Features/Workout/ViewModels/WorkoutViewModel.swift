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
    var currentRound: Int = 1
    
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
        // Validation du template
        guard !template.exerciseNames.isEmpty else {
            print("Erreur: Le template ne contient aucun exercice")
            return
        }
        
        let workout = Workout()
        workout.templateID = template.id
        workout.templateName = template.name
        workout.totalRounds = template.rounds
        
        // Créer les exercices pour chaque round
        for round in 1...template.rounds {
            let roundExercises = template.exerciseNames.enumerated().map { index, exerciseName in
                WorkoutExercise(
                    exerciseName: exerciseName,
                    round: round,
                    order: index
                )
            }
            workout.performances.append(contentsOf: roundExercises)
        }
        
        // Debug: Vérification de l'ordre des exercices
        print("Ordre des exercices créés :")
        for exercise in workout.performances {
            print("Round \(exercise.round) - Ordre \(exercise.order): \(exercise.exerciseName)")
        }
        
        // Initialiser le workout
        activeWorkout = workout
        isWorkoutActive = true
        currentRound = 1
        workoutStartTime = Date()
        
        // Sauvegarder et synchroniser
        modelContext.insert(workout)
        startTimer()
        if let workout = activeWorkout {
            WatchConnectivityService.shared.sendActiveWorkout(workout)
        }
    }
    
    func endWorkout() {
        guard let workout = activeWorkout else { return }
        
        // Finaliser le workout
        workout.completedAt = Date()
        workout.totalDuration = elapsedTime
        workout.totalDistance = workout.performances.reduce(0.0) { $0 + $1.distance }
        
        // Calculer les statistiques par round
        calculateRoundStatistics(for: workout)
        
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
        currentRound = 1
        elapsedTime = 0
        workoutProgress = 0
        workoutStartTime = nil
    }
    
    // MARK: - Exercise Management
    func isNextExercise(_ exercise: WorkoutExercise) -> Bool {
        guard let nextExercise = getNextExercise() else { return false }
        return nextExercise.id == exercise.id
    }
    
    private func getNextExercise() -> WorkoutExercise? {
        guard let workout = activeWorkout else { return nil }
        
        // Trier les exercices par round puis par ordre
        let sortedExercises = workout.performances.sorted { (exercise1: WorkoutExercise, exercise2: WorkoutExercise) in
            if exercise1.round == exercise2.round {
                return exercise1.order < exercise2.order
            }
            return exercise1.round < exercise2.round
        }
        
        // Trouver le premier exercice non complété
        return sortedExercises.first(where: { $0.completedAt == nil })
    }
    
    func completeExercise(_ exercise: WorkoutExercise, duration: TimeInterval, distance: Double, repetitions: Int) {
        exercise.duration = duration
        exercise.distance = distance
        exercise.repetitions = repetitions
        exercise.completedAt = Date()
        
        // Mettre à jour le round actuel si nécessaire
        if let nextExercise = getNextExercise(),
           nextExercise.round > currentRound {
            currentRound = nextExercise.round
        }
        
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
    func createTemplate(name: String, exerciseNames: [String], rounds: Int = 1) {
        // Validation des données
        guard !name.isEmpty else {
            print("Erreur: Le nom du template ne peut pas être vide")
            return
        }
        
        guard !exerciseNames.isEmpty else {
            print("Erreur: Le template doit contenir au moins un exercice")
            return
        }
        
        guard rounds > 0 else {
            print("Erreur: Le nombre de rounds doit être supérieur à 0")
            return
        }
        
        let template = WorkoutTemplate(name: name, rounds: rounds)
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
    
    // MARK: - New Template Management with TemplateExercise
    func createTemplateWithExercises(name: String, exercises: [TemplateExercise], rounds: Int = 1) {
        // Validation des données
        guard !name.isEmpty else {
            print("Erreur: Le nom du template ne peut pas être vide")
            return
        }
        
        guard !exercises.isEmpty else {
            print("Erreur: Le template doit contenir au moins un exercice")
            return
        }
        
        guard rounds > 0 else {
            print("Erreur: Le nombre de rounds doit être supérieur à 0")
            return
        }
        
        let template = WorkoutTemplate(name: name, rounds: rounds)
        
        // Ajouter les exercices au template
        for exercise in exercises {
            exercise.template = template
            modelContext.insert(exercise)
        }
        
        modelContext.insert(template)
        do {
            try modelContext.save()
            fetchTemplates()
            WatchConnectivityService.shared.sendTemplates()
        } catch {
            print("Erreur lors de la création du template : \(error)")
        }
    }
    
    func updateTemplateWithExercises(_ template: WorkoutTemplate, name: String, exercises: [TemplateExercise], rounds: Int) {
        // Validation des données
        guard !name.isEmpty else {
            print("Erreur: Le nom du template ne peut pas être vide")
            return
        }
        
        guard !exercises.isEmpty else {
            print("Erreur: Le template doit contenir au moins un exercice")
            return
        }
        
        guard rounds > 0 else {
            print("Erreur: Le nombre de rounds doit être supérieur à 0")
            return
        }
        
        // Mettre à jour le template
        template.name = name
        template.rounds = rounds
        
        // Supprimer les anciens exercices
        for exercise in template.exercises {
            modelContext.delete(exercise)
        }
        
        // Ajouter les nouveaux exercices
        for exercise in exercises {
            exercise.template = template
            modelContext.insert(exercise)
        }
        
        do {
            try modelContext.save()
            fetchTemplates()
            WatchConnectivityService.shared.sendTemplates()
        } catch {
            print("Erreur lors de la mise à jour du template : \(error)")
        }
    }
    
    func updateTemplate(_ template: WorkoutTemplate, name: String, exerciseNames: [String], rounds: Int) {
        // Validation des données
        guard !name.isEmpty else {
            print("Erreur: Le nom du template ne peut pas être vide")
            return
        }
        
        guard !exerciseNames.isEmpty else {
            print("Erreur: Le template doit contenir au moins un exercice")
            return
        }
        
        guard rounds > 0 else {
            print("Erreur: Le nombre de rounds doit être supérieur à 0")
            return
        }
        
        // Mettre à jour le template
        template.name = name
        template.exerciseNames = exerciseNames
        template.rounds = rounds
        
        do {
            try modelContext.save()
            fetchTemplates()
            WatchConnectivityService.shared.sendTemplates()
        } catch {
            print("Erreur lors de la mise à jour du template : \(error)")
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        // Sauvegarder l'ID avant la suppression
        let templateId = template.id
        
        // Supprimer le template
        modelContext.delete(template)
        do {
            try modelContext.save()
            
            // Synchroniser avec la montre
            WatchConnectivityService.shared.sendTemplateDeleted(templateId)
            WatchConnectivityService.shared.sendTemplates()
            
            fetchTemplates() // Recharger les templates après la suppression
        } catch {
            print("Erreur lors de la suppression du template : \(error)")
        }
    }
    
    func deleteAllTemplates() {
        // Sauvegarder les IDs avant la suppression
        let templateIds = templates.map { $0.id }
        
        // Supprimer tous les templates
        for template in templates {
            modelContext.delete(template)
        }
        do {
            try modelContext.save()
            
            // Synchroniser avec la montre
            for templateId in templateIds {
                WatchConnectivityService.shared.sendTemplateDeleted(templateId)
            }
            WatchConnectivityService.shared.sendTemplates()
            
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
    
    // MARK: - Private Methods
    private func calculateRoundStatistics(for workout: Workout) {
        let rounds = Set(workout.performances.map { $0.round }).sorted()
        
        for round in rounds {
            let roundExercises = workout.performances.filter { $0.round == round }
            let roundDuration = roundExercises.reduce(0.0) { $0 + $1.duration }
            let roundDistance = roundExercises.reduce(0.0) { $0 + $1.distance }
            
            // Ici vous pouvez stocker ces statistiques dans le workout si nécessaire
            print("Round \(round): Durée = \(roundDuration.formatted), Distance = \(roundDistance)m")
        }
    }
    
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
