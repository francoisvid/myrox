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
    var showWorkoutCompletion = false
    var completedWorkout: Workout?
    
    // MARK: - État Workflow
    var activeWorkout: Workout?
    var isWorkoutActive = false
    var elapsedTime: TimeInterval = 0
    var workoutProgress: Double = 0
    var currentRound: Int = 1
    
    // MARK: - Loading states
    var isCreatingTemplate = false
    var templateCreationError: String?
    
    // MARK: - Timer
    private var timer: Timer?
    private var workoutStartTime: Date?
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let templateRepository: TemplateRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    
    // MARK: - Templates
    var templates: [WorkoutTemplate] = []
    var apiTemplates: [APITemplate] = [] // Pour accéder aux infos API
    var apiTemplatesLoaded: Bool = false // Pour déclencher le rafraîchissement de la vue
    
    init(
        modelContext: ModelContext, 
        templateRepository: TemplateRepositoryProtocol? = nil,
        workoutRepository: WorkoutRepositoryProtocol? = nil
    ) {
        self.modelContext = modelContext
        self.templateRepository = templateRepository ?? TemplateRepository(modelContext: modelContext)
        self.workoutRepository = workoutRepository ?? WorkoutRepository(modelContext: modelContext)
        fetchTemplates()
    }
    
    // MARK: - Méthode pour charger les templates
    func fetchTemplates() {
        templates = templateRepository.getCachedTemplates()
        // Synchroniser avec Apple Watch
        WatchConnectivityService.shared.sendTemplates()
        
        // Charger les templates API au démarrage pour avoir les métadonnées
        Task {
            await loadAPITemplates()
        }
    }
    
    // MARK: - Méthode pour charger les templates API
    @MainActor
    private func loadAPITemplates() async {
        do {
            let personalTemplates = try await templateRepository.fetchPersonalTemplates()
            let assignedTemplates = try await templateRepository.fetchAssignedTemplates()
            
            apiTemplates = personalTemplates + assignedTemplates
            apiTemplatesLoaded = true // Déclenche le rafraîchissement de la vue
            print("📋 Templates API chargés au démarrage: \(personalTemplates.count) personnels, \(assignedTemplates.count) assignés")
        } catch {
            print("⚠️ Erreur lors du chargement des templates API au démarrage: \(error)")
        }
    }
    
    // MARK: - Méthode pour récupérer l'APITemplate correspondant à un WorkoutTemplate
    func getAPITemplate(for workoutTemplate: WorkoutTemplate) -> APITemplate? {
        return apiTemplates.first { $0.uuid == workoutTemplate.id }
    }
    
    // MARK: - Méthode pour synchroniser les templates depuis l'API
    @MainActor
    func refreshTemplatesFromAPI() async {
        do {
            print("🔄 Synchronisation des templates depuis l'API...")
            
            // Récupérer les templates API
            let personalTemplates = try await templateRepository.fetchPersonalTemplates()
            let assignedTemplates = try await templateRepository.fetchAssignedTemplates()
            
            // Stocker les templates API pour accéder aux métadonnées
            apiTemplates = personalTemplates + assignedTemplates
            print("📋 Templates API chargés: \(personalTemplates.count) personnels, \(assignedTemplates.count) assignés")
            
            // Synchroniser avec le cache local
            try await templateRepository.syncTemplatesWithCache()
            templates = templateRepository.getCachedTemplates()
            print("✅ Templates synchronisés avec succès")
            
            // Synchroniser avec Apple Watch après mise à jour depuis l'API
            WatchConnectivityService.shared.sendTemplates()
            print("⌚ Templates synchronisés avec Apple Watch")
        } catch {
            print("❌ Erreur lors de la synchronisation des templates: \(error)")
        }
    }
    
    // MARK: - Workout Actions
    func startWorkout(from template: WorkoutTemplate) {
        // 🔄 SYNC Personal Bests avant de démarrer le workout
        // pour avoir les données les plus récentes depuis l'API
        Task {
            await syncPersonalBestsFromAPI()
        }
        
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
                
                if let targetTime = templateExercise.targetDuration {
                    workoutExercise.targetDuration = targetTime
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
        
        // Sauvegarder localement
        do {
            try modelContext.save()
            WatchConnectivityService.shared.sendWorkoutCount()
            
            // Synchroniser avec l'API en arrière-plan
            Task {
                do {
                    try await workoutRepository.syncCompletedWorkout(workout)
                    print("✅ Workout synchronisé avec l'API")
                    
                    // 🏆 OPTIMISATION P0: L'API calcule les Personal Bests automatiquement
                    // Récupérer les Personal Bests mis à jour depuis l'API
                    await syncPersonalBestsFromAPI()
                    
                } catch {
                    print("⚠️ Erreur synchronisation API (workout sauvé localement): \(error)")
                    // Le workout reste sauvé localement même si la sync API échoue
                }
            }
            
            // 🔔 SUPPRIMÉ : Plus de notification automatique pour les workouts iOS
            // La modale de partage s'ouvre directement à la place
            
            // Garder seulement les notifications de records personnels
            Task {
                let personalRecords = workout.performances.filter { $0.isPersonalRecord }
                for record in personalRecords {
                    await NotificationService.shared.schedulePersonalRecordNotification(
                        exerciseName: record.exerciseName,
                        recordType: "Temps"
                    )
                }
            }
            
        } catch {
            print("Erreur lors de la sauvegarde du workout : \(error)")
        }
        
        // Préparer l'affichage de la vue de fin de séance
        completedWorkout = workout
        showWorkoutCompletion = true
        
        // Arrêter le timer mais garder l'état workout actif jusqu'à la fermeture de la vue de completion
        stopTimer()
        
        // NE PAS réinitialiser activeWorkout et isWorkoutActive ici
        // Cela sera fait quand l'utilisateur fermera la vue de completion
    }
    
    // Nouvelle méthode pour nettoyer l'état après fermeture de la vue de completion
    func cleanupAfterWorkoutCompletion() {
        activeWorkout = nil
        isWorkoutActive = false
        currentRound = 1
        elapsedTime = 0
        workoutProgress = 0
        workoutStartTime = nil
        completedWorkout = nil
    }
    
    // MARK: - Cancel Workout
    func cancelWorkout() {
        guard let workout = activeWorkout else { return }
        
        print("🔴 Annulation du workout: \(workout.templateName)")
        
        // Arrêter le timer
        stopTimer()
        
        // Supprimer le workout de la base de données (il n'était pas encore terminé)
        modelContext.delete(workout)
        do {
            try modelContext.save()
            print("✅ Workout annulé et supprimé de la base de données")
        } catch {
            print("❌ Erreur lors de la suppression du workout annulé: \(error)")
        }
        

        
        // Réinitialiser tous les états
        activeWorkout = nil
        isWorkoutActive = false
        currentRound = 1
        elapsedTime = 0
        workoutProgress = 0
        workoutStartTime = nil
        completedWorkout = nil
        
        print("✅ Workout annulé et état réinitialisé")
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
        Task {
            await createTemplateAsync(name: name, exercises: exercises, rounds: rounds)
        }
    }
    
    private func createTemplateAsync(name: String, exercises: [TemplateExercise], rounds: Int = 1) async {
        print("🚀 WorkoutViewModel.createTemplateAsync() appelé avec:")
        print("   - Nom: '\(name)'")
        print("   - Exercices: \(exercises.count)")
        print("   - Rounds: \(rounds)")
        
        // Debug des exercices reçus
        for (index, exercise) in exercises.enumerated() {
            print("   - Exercice \(index + 1): '\(exercise.exerciseName)' (ordre: \(exercise.order))")
        }
        
        // Validation des données
        guard !name.isEmpty else {
            templateCreationError = "Le nom du template ne peut pas être vide"
            return
        }
        
        guard rounds > 0 else {
            templateCreationError = "Le nombre de rounds doit être supérieur à 0"
            return
        }
        
        isCreatingTemplate = true
        templateCreationError = nil
        
        do {
            print("🔄 Début chargement des exercices API...")
            
            // Charger les exercices API si pas encore fait
            await ExerciseMapper.shared.loadExercises()
            
            print("✅ Exercices API chargés, début mapping...")
            
            // Mapper les exercices iOS vers les exercices API
            let mappedExercises = ExerciseMapper.shared.mapTemplateExercises(exercises)
            
            print("🔄 Mapping des exercices: \(exercises.count) exercices iOS → \(mappedExercises.count) exercices API")
            
            // Create template via API avec les exercices mappés
            let request = CreateTemplateRequest(
                name: name,
                rounds: rounds,
                exercises: mappedExercises
            )
            
            _ = try await templateRepository.createTemplate(request)
            
            // Sync cache and reload templates sur la main queue
            await MainActor.run {
                Task {
                    try await templateRepository.syncTemplatesWithCache()
                    fetchTemplates()
                    
                    // Sync with Watch
                    WatchConnectivityService.shared.sendTemplates()
                    
                    print("✅ Template créé et synchronisé avec l'API: \(name) avec \(mappedExercises.count) exercices")
                }
            }
            
        } catch {
            print("❌ Erreur lors de la création du template: \(error)")
            templateCreationError = "Erreur lors de la création du template"
            
            // Fallback: Create locally only if API fails
            await MainActor.run {
                createTemplateLocally(name: name, exercises: exercises, rounds: rounds)
            }
        }
        
        isCreatingTemplate = false
    }
    
    private func createTemplateLocally(name: String, exercises: [TemplateExercise], rounds: Int) {
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
            print("⚠️ Template créé localement uniquement: \(name)")
        } catch {
            print("❌ Erreur lors de la création locale du template: \(error)")
            templateCreationError = "Erreur lors de la création du template"
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

        print("🔄 Début mise à jour template: \(template.name) -> \(name)")
        
        Task {
            do {
                // Charger les exercices API d'abord
                await ExerciseMapper.shared.loadExercises()
                
                // Debug des exercices iOS avant mapping
                print("📋 WorkoutViewModel.updateTemplate - Exercices iOS reçus:")
                for (index, exercise) in exercises.enumerated() {
                    print("   [\(index)] '\(exercise.exerciseName)' (ordre: \(exercise.order), distance: \(exercise.targetDistance ?? 0), reps: \(exercise.targetRepetitions ?? 0))")
                }
                
                // D'abord, préparer la liste des exercices pour l'API
                let mappedExercises = await ExerciseMapper.shared.mapTemplateExercises(exercises)
                
                // Debug des exercices mappés
                print("🔄 WorkoutViewModel.updateTemplate - Exercices mappés pour l'API:")
                for (index, exercise) in mappedExercises.enumerated() {
                    print("   [\(index)] exerciseId: \(exercise.exerciseId), ordre: \(exercise.order), distance: \(exercise.targetDistance ?? 0), reps: \(exercise.targetRepetitions ?? 0))")
                }
                
                // Créer la requête de mise à jour
                let updateRequest = UpdateTemplateRequest(
                    id: template.id.uuidString,
                    name: name,
                    rounds: rounds,
                    exercises: mappedExercises
                )
                
                print("🌐 WorkoutViewModel.updateTemplate - Envoi requête API avec \(mappedExercises.count) exercices")
                
                // 1. Mettre à jour via l'API
                _ = try await templateRepository.updateTemplate(updateRequest)
                print("✅ Template mis à jour sur l'API")
                
                // 2. Synchroniser avec le cache local
                try await templateRepository.syncTemplatesWithCache()
                
                // 3. Recharger les templates
                await MainActor.run {
                    fetchTemplates()
                    WatchConnectivityService.shared.sendTemplates()
                    print("✅ Template mis à jour localement")
                }
                
            } catch {
                print("❌ Erreur lors de la mise à jour du template via l'API: \(error)")
                
                // Fallback: mettre à jour localement seulement
                await MainActor.run {
                    updateTemplateLocally(template, name: name, exercises: exercises, rounds: rounds)
                    print("⚠️ Template mis à jour localement uniquement")
                }
            }
        }
    }
    
    // Méthode privée pour la mise à jour locale uniquement (fallback)
    private func updateTemplateLocally(_ template: WorkoutTemplate, name: String, exercises: [TemplateExercise], rounds: Int) {
        print("Début mise à jour locale template: \(template.name) -> \(name)")
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
                $0.exerciseName == newExercise.exerciseName && $0.order == index  // Ordre commence à 0
            }) {
                // Mettre à jour l'exercice existant
                existingExercise.targetDistance = newExercise.targetDistance
                existingExercise.targetRepetitions = newExercise.targetRepetitions
                existingExercise.order = index  // Ordre commence à 0
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
                    existingExercise.order = index  // Ordre commence à 0
                    exercisesToKeep.append(existingExercise)
                    print("Réutilisation exercice existant: \(existingExercise.exerciseName)")
                } else {
                    // Créer un nouvel exercice
                    let templateExercise = TemplateExercise(
                        exerciseName: newExercise.exerciseName,
                        targetDistance: newExercise.targetDistance,
                        targetRepetitions: newExercise.targetRepetitions,
                        order: index  // Ordre commence à 0
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
            print("Sauvegarde locale réussie")
            fetchTemplates()
            WatchConnectivityService.shared.sendTemplates()
        } catch {
            print("Erreur lors de la mise à jour locale du template : \(error)")
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        print("🗑️ Début suppression template: \(template.name)")
        
        Task {
            do {
                // 1. D'abord, supprimer via l'API
                try await templateRepository.deleteTemplate(id: template.id.uuidString)
                print("✅ Template supprimé de l'API")
                
                // 2. Synchroniser avec le cache local
                try await templateRepository.syncTemplatesWithCache()
                
                // 3. Recharger les templates
                await MainActor.run {
                    fetchTemplates()
                    WatchConnectivityService.shared.sendTemplates()
                    print("✅ Template supprimé et liste mise à jour")
                }
                
            } catch {
                print("❌ Erreur lors de la suppression du template via l'API: \(error)")
                
                // Fallback: supprimer localement seulement
                await MainActor.run {
                    deleteTemplateLocally(template)
                    print("⚠️ Template supprimé localement uniquement")
                }
            }
        }
    }
    
    // Méthode privée pour la suppression locale uniquement (fallback)
    private func deleteTemplateLocally(_ template: WorkoutTemplate) {
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
            print("Erreur lors de la suppression locale du template : \(error)")
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
    
    // MARK: - Test Functions (à supprimer en production)
    func testNotifications() {
        Task {
            print("🧪 === TEST DES NOTIFICATIONS ===")
            
            // 1. Vérifier l'état détaillé des permissions
            await NotificationService.shared.checkDetailedNotificationStatus()
            
            // 2. Tester une notification immédiate d'abord
            await NotificationService.shared.sendImmediateTestNotification()
            
            // 3. Attendre un peu puis continuer avec les tests normaux
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
            
            // 4. Tester la demande de permission (au cas où)
            let granted = await NotificationService.shared.requestPermission()
            print("🔐 Permissions de notification: \(granted)")
            
            // 5. Vérifier les notifications en attente avant
            await NotificationService.shared.checkPendingNotifications()
            
            // 6. Créer un workout de test
            let testWorkout = Workout()
            testWorkout.templateName = "Test Séance"
            testWorkout.totalDuration = 1200 // 20 minutes
            testWorkout.completedAt = Date()
            
            // 7. Tester la notification de fin de séance
            await NotificationService.shared.scheduleWorkoutCompletionNotification(for: testWorkout)
            
            // 8. Tester une notification de record personnel
            await NotificationService.shared.schedulePersonalRecordNotification(
                exerciseName: "SkiErg",
                recordType: "Temps"
            )
            
            // 9. Vérifier les notifications en attente après
            await NotificationService.shared.checkPendingNotifications()
            
            print("🎯 === FIN DU TEST DES NOTIFICATIONS ===")
        }
    }
    
    func testWatchNotification() {
        Task {
            print("⌚ === TEST NOTIFICATION APPLE WATCH ===")
            
            // 1. Vérifier les permissions d'abord
            await NotificationService.shared.checkDetailedNotificationStatus()
            
            // 2. Test notification immédiate Watch
            await NotificationService.shared.sendImmediateTestNotification()
            
            // 3. Créer un workout de test simulant une séance Watch
            let watchWorkout = Workout()
            watchWorkout.templateName = "LA DÉFENSE"
            watchWorkout.totalDuration = 1200 // 20 minutes
            watchWorkout.completedAt = Date()
            
            // Ajouter 6 exercices pour tester le mode compact
            let exercise1 = WorkoutExercise(exerciseName: "Run", round: 1, order: 0)
            exercise1.duration = 45 // ~45 secondes pour 150m
            exercise1.distance = 150
            exercise1.completedAt = Date()
            
            let exercise2 = WorkoutExercise(exerciseName: "Kettlebell Swings", round: 1, order: 1)
            exercise2.duration = 90 // ~1min30 pour 30 swings
            exercise2.repetitions = 30
            exercise2.completedAt = Date()
            
            let exercise3 = WorkoutExercise(exerciseName: "Run", round: 1, order: 2)
            exercise3.duration = 45 // ~45 secondes pour 150m
            exercise3.distance = 150
            exercise3.completedAt = Date()
            
            let exercise4 = WorkoutExercise(exerciseName: "Wall Balls", round: 1, order: 3)
            exercise4.duration = 180 // ~3 minutes pour 40 wall balls
            exercise4.repetitions = 40
            exercise4.completedAt = Date()
            exercise4.isPersonalRecord = true // 🏆 Record personnel !
            
            let exercise5 = WorkoutExercise(exerciseName: "Run", round: 1, order: 4)
            exercise5.duration = 45 // ~45 secondes pour 150m
            exercise5.distance = 150
            exercise5.completedAt = Date()
            
            let exercise6 = WorkoutExercise(exerciseName: "Sled Pull", round: 1, order: 5)
            exercise6.duration = 60 // ~1 minute pour 50m de sled
            exercise6.distance = 50
            exercise6.completedAt = Date()
            exercise6.isPersonalRecord = true // 🏆 Autre record personnel !
            
            watchWorkout.performances = [exercise1, exercise2, exercise3, exercise4, exercise5, exercise6]
            
            // Calculer la distance totale
            watchWorkout.totalDistance = watchWorkout.performances.reduce(0.0) { $0 + $1.distance }
            
            // Sauvegarder temporairement
            modelContext.insert(watchWorkout)
            try? modelContext.save()
            
            // 4. Tester la notification spécifique Watch
            await NotificationService.shared.scheduleWorkoutCompletionFromWatchNotification(for: watchWorkout)
            
            print("📱⌚ Test notification Apple Watch envoyée")
            print("⌚ === FIN TEST NOTIFICATION APPLE WATCH ===")
        }
    }
    
    // MARK: - Personal Best Calculation (SUPPRIMÉ - Optimisation P0)
    // 
    // La méthode calculatePersonalBests() a été supprimée dans le cadre de l'optimisation P0
    // Les Personal Bests sont maintenant calculés uniquement côté API pour éviter le double calcul
    // Voir syncPersonalBestsFromAPI() pour la nouvelle implémentation
    
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
    
    // MARK: - Personal Best Sync (Optimisé P0)
    
    /// Synchronise les Personal Bests depuis l'API après qu'un workout soit complété
    /// L'API calcule automatiquement les Personal Bests, on récupère juste les résultats
    func syncPersonalBestsFromAPI() async {
        print("🏆 Sync Personal Bests depuis l'API (optimisé - pas de double calcul)")
        
        do {
            let personalBestRepository = PersonalBestRepository(modelContext: modelContext)
            
            // Synchroniser avec l'API (récupère les Personal Bests calculés par l'API)
            try await personalBestRepository.syncPersonalBestsWithCache()
            
            print("✅ Personal Bests synchronisés depuis l'API")
            
        } catch {
            print("❌ Erreur sync Personal Bests depuis API: \(error)")
            // En cas d'erreur, l'ancienne version locale reste
        }
    }
}
