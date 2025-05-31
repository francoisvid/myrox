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
        let templateExercises = template.exercises.sorted(by: { $0.order < $1.order })
        
        guard !templateExercises.isEmpty else {
            print("Erreur: Le template ne contient aucun exercice")
            return
        }
        
        let workout = Workout()
        workout.templateID = template.id
        workout.templateName = template.name
        workout.totalRounds = template.rounds
        
        // Créer les exercices pour chaque round avec les paramètres des TemplateExercise
        for round in 1...template.rounds {
            let roundExercises = templateExercises.enumerated().map { index, templateExercise in
                let workoutExercise = WorkoutExercise(
                    exerciseName: templateExercise.exerciseName,
                    round: round,
                    order: index
                )
                
                // Pré-remplir avec les valeurs cibles du template si disponibles
                if let targetDistance = templateExercise.targetDistance {
                    workoutExercise.distance = targetDistance
                }
                
                if let targetReps = templateExercise.targetRepetitions {
                    workoutExercise.repetitions = targetReps
                }
                
                return workoutExercise
            }
            workout.performances.append(contentsOf: roundExercises)
        }
        
        // Debug: Vérification de l'ordre des exercices
        print("Ordre des exercices créés :")
        for exercise in workout.performances {
            let params = [
                exercise.distance > 0 ? "\(Int(exercise.distance))m" : "",
                exercise.repetitions > 0 ? "\(exercise.repetitions) reps" : ""
            ].filter { !$0.isEmpty }.joined(separator: ", ")
            print("Round \(exercise.round) - Ordre \(exercise.order): \(exercise.exerciseName) \(params)")
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
    func createTemplate(name: String, exercises: [TemplateExercise], rounds: Int = 1) {
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
    
    func updateTemplate(_ template: WorkoutTemplate, name: String, exercises: [TemplateExercise], rounds: Int) {
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
        
        print("Début mise à jour template: \(template.name) -> \(name)")
        print("Exercices existants: \(template.exercises.count)")
        print("Nouveaux exercices: \(exercises.count)")
        
        // Mettre à jour le template
        template.name = name
        template.rounds = rounds
        
        // Récupérer les exercices existants
        let existingExercises = template.exercises
        
        // Créer un mappage des exercices à conserver/mettre à jour/ajouter
        var exercisesToKeep: [TemplateExercise] = []
        var exercisesToAdd: [TemplateExercise] = []
        
        for (index, newExercise) in exercises.enumerated() {
            // Chercher un exercice existant correspondant (même nom, même ordre)
            if let existingExercise = existingExercises.first(where: { 
                $0.exerciseName == newExercise.exerciseName && $0.order == index 
            }) {
                // Mettre à jour l'exercice existant
                existingExercise.targetDistance = newExercise.targetDistance
                existingExercise.targetRepetitions = newExercise.targetRepetitions
                existingExercise.order = index
                exercisesToKeep.append(existingExercise)
                print("Mise à jour exercice existant: \(existingExercise.exerciseName)")
            } else {
                // Chercher un exercice existant avec le même nom mais ordre différent
                if let existingExercise = existingExercises.first(where: { 
                    $0.exerciseName == newExercise.exerciseName && !exercisesToKeep.contains($0)
                }) {
                    // Réutiliser et mettre à jour l'exercice existant
                    existingExercise.targetDistance = newExercise.targetDistance
                    existingExercise.targetRepetitions = newExercise.targetRepetitions
                    existingExercise.order = index
                    exercisesToKeep.append(existingExercise)
                    print("Réutilisation exercice existant: \(existingExercise.exerciseName)")
                } else {
                    // Créer un nouvel exercice
                    let templateExercise = TemplateExercise(
                        exerciseName: newExercise.exerciseName,
                        targetDistance: newExercise.targetDistance,
                        targetRepetitions: newExercise.targetRepetitions,
                        order: index
                    )
                    templateExercise.template = template
                    exercisesToAdd.append(templateExercise)
                    print("Création nouvel exercice: \(templateExercise.exerciseName)")
                }
            }
        }
        
        // Supprimer les exercices qui ne sont plus nécessaires
        let exercisesToDelete = existingExercises.filter { !exercisesToKeep.contains($0) }
        for exercise in exercisesToDelete {
            print("Suppression exercice: \(exercise.exerciseName)")
            modelContext.delete(exercise)
        }
        
        // Ajouter les nouveaux exercices
        for exercise in exercisesToAdd {
            modelContext.insert(exercise)
        }
        
        print("Exercices conservés: \(exercisesToKeep.count)")
        print("Exercices ajoutés: \(exercisesToAdd.count)")
        print("Exercices supprimés: \(exercisesToDelete.count)")
        
        do {
            try modelContext.save()
            print("Sauvegarde réussie")
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
    
    // MARK: - Migration/Cleanup
    func cleanupLegacyTemplates() {
        print("🧹 Début du nettoyage des anciens templates...")
        
        do {
            let descriptor = FetchDescriptor<WorkoutTemplate>()
            let allTemplates = try modelContext.fetch(descriptor)
            
            var deletedCount = 0
            var keptCount = 0
            
            for template in allTemplates {
                if template.exercises.isEmpty {
                    print("❌ Suppression template vide: \(template.name)")
                    modelContext.delete(template)
                    deletedCount += 1
                } else {
                    print("✅ Conservation template valide: \(template.name) (\(template.exercises.count) exercices)")
                    keptCount += 1
                }
            }
            
            // Sauvegarder les changements
            try modelContext.save()
            
            print("🎯 Nettoyage terminé:")
            print("   - Templates supprimés: \(deletedCount)")
            print("   - Templates conservés: \(keptCount)")
            
            // Recharger les templates et synchroniser
            fetchTemplates()
            WatchConnectivityService.shared.sendTemplates()
            
        } catch {
            print("❌ Erreur lors du nettoyage des anciens templates: \(error)")
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
