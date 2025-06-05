import Foundation
import SwiftData
import FirebaseAuth

protocol WorkoutRepositoryProtocol {
    // API Methods
    func fetchWorkouts() async throws -> [APIWorkout]
    func createWorkout(_ request: CreateWorkoutRequest) async throws -> APIWorkout
    func updateWorkout(workoutId: UUID, _ request: UpdateWorkoutRequest) async throws -> APIWorkout
    func deleteWorkout(workoutId: UUID) async throws
    func fetchPersonalBests() async throws -> [APIPersonalBest]
    
    // Local Cache Methods  
    func syncWorkoutsWithCache() async throws
    func getCachedWorkouts() -> [Workout]
    func getCachedWorkout(id: UUID) -> Workout?
    
    // Local Workout Management
    func saveWorkoutLocally(_ workout: Workout) throws
    func syncCompletedWorkout(_ workout: Workout) async throws
}

class WorkoutRepository: WorkoutRepositoryProtocol {
    private let apiService: APIService
    private let modelContext: ModelContext
    
    init(apiService: APIService = APIService.shared, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
    }
    
    // MARK: - API Methods
    
    func fetchWorkouts() async throws -> [APIWorkout] {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.fetchWorkouts(firebaseUID: endpoints.firebaseUID)
    }
    
    func createWorkout(_ request: CreateWorkoutRequest) async throws -> APIWorkout {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.createWorkout(firebaseUID: endpoints.firebaseUID, request)
    }
    
    func updateWorkout(workoutId: UUID, _ request: UpdateWorkoutRequest) async throws -> APIWorkout {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.updateWorkout(firebaseUID: endpoints.firebaseUID, workoutId: workoutId, request)
    }
    
    func deleteWorkout(workoutId: UUID) async throws {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        try await apiService.deleteWorkout(firebaseUID: endpoints.firebaseUID, workoutId: workoutId)
    }
    
    func fetchPersonalBests() async throws -> [APIPersonalBest] {
        guard let endpoints = APIEndpoints.forCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await apiService.fetchPersonalBests(firebaseUID: endpoints.firebaseUID)
    }
    
    // MARK: - Cache Management
    
    func syncWorkoutsWithCache() async throws {
        // 1. Fetch workouts from API
        let apiWorkouts = try await fetchWorkouts()
        
        // 2. Get existing cached workouts
        let existingWorkouts = getCachedWorkouts()
        let existingWorkoutIds = Set(existingWorkouts.map { $0.id })
        
        // 3. Determine which workouts to update/add/remove
        let apiWorkoutIds = Set(apiWorkouts.map { $0.uuid })
        
        // Remove workouts that no longer exist in API
        for workout in existingWorkouts {
            if !apiWorkoutIds.contains(workout.id) {
                modelContext.delete(workout)
            }
        }
        
        // Add or update workouts from API
        for apiWorkout in apiWorkouts {
            if let existingWorkout = existingWorkouts.first(where: { $0.id == apiWorkout.uuid }) {
                // Update existing workout
                updateLocalWorkout(existingWorkout, from: apiWorkout)
            } else {
                // Add new workout
                let newWorkout = convertAPIWorkoutToSwiftData(apiWorkout)
                modelContext.insert(newWorkout)
            }
        }
        
        // Save changes
        try modelContext.save()
    }
    
    func getCachedWorkouts() -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching cached workouts: \(error)")
            return []
        }
    }
    
    func getCachedWorkout(id: UUID) -> Workout? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching workout with id \(id): \(error)")
            return nil
        }
    }
    
    // MARK: - Local Workout Management
    
    func saveWorkoutLocally(_ workout: Workout) throws {
        modelContext.insert(workout)
        try modelContext.save()
    }
    
    // Fonction pour forcer le reset du cache d'exercices (à appeler une seule fois)
    func resetExerciseCache() throws {
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(descriptor)
        
        for exercise in exercises {
            modelContext.delete(exercise)
        }
        
        try modelContext.save()
        print("🔄 Cache d'exercices réinitialisé - \(exercises.count) exercices supprimés")
    }
    
    func syncCompletedWorkout(_ workout: Workout) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        
        // Créer le workout dans l'API s'il n'existe pas déjà
        // Ou le mettre à jour s'il est maintenant complété
        
        if workout.completedAt != nil {
            // Workout complété - créer dans l'API
            let createRequest = convertWorkoutToCreateRequest(workout)
            let createdWorkout = try await createWorkout(createRequest)
            
            // ✅ IMPORTANT: Mettre à jour l'ID local avec l'ID API
            workout.id = createdWorkout.uuid
            print("🔄 ID workout mis à jour: local -> API (\(createdWorkout.id))")
            
            // ✅ IMPORTANT: Mapper les IDs des exercices API vers les exercices locaux
            let sortedLocalExercises = workout.performances.sorted { first, second in
                if first.round != second.round {
                    return first.round < second.round
                }
                return first.order < second.order
            }
            
            let sortedAPIExercises = createdWorkout.exercises.sorted { $0.order < $1.order }
            
            // Mapper les IDs (même ordre dans les deux listes)
            for (index, localExercise) in sortedLocalExercises.enumerated() {
                if index < sortedAPIExercises.count {
                    let apiExercise = sortedAPIExercises[index]
                    let oldId = localExercise.id
                    localExercise.id = UUID(uuidString: apiExercise.id) ?? UUID()
                    print("🔄 ID exercice mappé: \(oldId) -> \(apiExercise.id)")
                }
            }
            
            // Sauvegarder les changements d'IDs
            try modelContext.save()
            
            // Si complété, également envoyer les exercices complétés avec les bons IDs
            if let _ = workout.completedAt {
                let updateRequest = convertWorkoutToUpdateRequest(workout)
                _ = try await updateWorkout(workoutId: workout.id, updateRequest)
            }
        }
    }
    
    // MARK: - Conversion Methods
    
    private func convertAPIWorkoutToSwiftData(_ apiWorkout: APIWorkout) -> Workout {
        let workout = Workout()
        workout.id = apiWorkout.uuid
        workout.templateID = apiWorkout.template?.id != nil ? UUID(uuidString: apiWorkout.template!.id) : nil
        workout.templateName = apiWorkout.template?.name
        workout.startedAt = apiWorkout.startDate
        workout.completedAt = apiWorkout.completionDate
        workout.totalDuration = TimeInterval(apiWorkout.totalDuration ?? 0)
        workout.totalDistance = apiWorkout.exercises.reduce(0.0) { $0 + ($1.distanceCompleted ?? 0) }
        
        // Convert API exercises to SwiftData WorkoutExercise
        for apiExercise in apiWorkout.exercises {
            let workoutExercise = WorkoutExercise(
                exerciseName: apiExercise.exercise.name,
                round: 1, // Pour l'instant, on assume 1 round depuis l'API
                order: apiExercise.order
            )
            
            workoutExercise.duration = TimeInterval(apiExercise.durationCompleted ?? 0)
            workoutExercise.distance = apiExercise.distanceCompleted ?? 0
            workoutExercise.repetitions = apiExercise.repsCompleted ?? 0
            workoutExercise.completedAt = apiExercise.completionDate
            
            workout.performances.append(workoutExercise)
        }
        
        return workout
    }
    
    private func updateLocalWorkout(_ localWorkout: Workout, from apiWorkout: APIWorkout) {
        localWorkout.templateName = apiWorkout.template?.name
        localWorkout.completedAt = apiWorkout.completionDate
        localWorkout.totalDuration = TimeInterval(apiWorkout.totalDuration ?? 0)
        localWorkout.totalDistance = apiWorkout.exercises.reduce(0.0) { $0 + ($1.distanceCompleted ?? 0) }
        
        // Clear existing exercises and add updated ones
        localWorkout.performances.removeAll()
        
        for apiExercise in apiWorkout.exercises {
            let workoutExercise = WorkoutExercise(
                exerciseName: apiExercise.exercise.name,
                round: 1,
                order: apiExercise.order
            )
            
            workoutExercise.duration = TimeInterval(apiExercise.durationCompleted ?? 0)
            workoutExercise.distance = apiExercise.distanceCompleted ?? 0
            workoutExercise.repetitions = apiExercise.repsCompleted ?? 0
            workoutExercise.completedAt = apiExercise.completionDate
            
            localWorkout.performances.append(workoutExercise)
        }
    }
    
    private func convertWorkoutToCreateRequest(_ workout: Workout) -> CreateWorkoutRequest {
        // Trier les exercices par round puis par ordre pour avoir une séquence correcte
        let sortedExercises = workout.performances.sorted { first, second in
            if first.round != second.round {
                return first.round < second.round
            }
            return first.order < second.order
        }
        
        let exercises = sortedExercises.enumerated().map { (index, exercise) in
            CreateWorkoutExerciseRequest(
                exerciseId: getExerciseIdByName(exercise.exerciseName).lowercased(), // Forcer minuscules
                order: index, // Ordre séquentiel 0,1,2,3,4,5...
                sets: nil,
                targetReps: exercise.repetitions > 0 ? exercise.repetitions : nil,
                targetDuration: exercise.duration > 0 ? Int(exercise.duration) : nil,
                targetDistance: exercise.distance > 0 ? exercise.distance : nil,
                targetWeight: nil,
                restTime: nil
            )
        }
        
        return CreateWorkoutRequest(
            templateId: workout.templateID?.uuidString.lowercased(), // Forcer minuscules
            name: workout.templateName,
            startedAt: ISO8601DateFormatter().string(from: workout.startedAt),
            exercises: exercises
        )
    }
    
    // Fonction pour résoudre les IDs d'exercices depuis le cache local
    private func getExerciseIdByName(_ exerciseName: String) -> String {
        // Extraire le nom de base de l'exercice (supprimer distance/répétitions)
        let baseName = extractBaseExerciseName(from: exerciseName)
        
        // Chercher l'exercice dans le cache local
        let descriptor = FetchDescriptor<Exercise>()
        
        do {
            let exercises = try modelContext.fetch(descriptor)
            
            // Recherche manuelle pour éviter les problèmes de predicate SwiftData
            if let exercise = exercises.first(where: { exercise in
                exercise.name.lowercased() == baseName.lowercased() ||
                exercise.name.lowercased().contains(baseName.lowercased()) ||
                baseName.lowercased().contains(exercise.name.lowercased())
            }) {
                print("✅ Exercice trouvé dans le cache: '\(exerciseName)' -> '\(exercise.name)' (ID: \(exercise.id.uuidString))")
                return exercise.id.uuidString
            }
        } catch {
            print("❌ Erreur lors de la recherche d'exercice: \(error)")
        }
        
        // Fallback final: utiliser directement le nom de base
        print("⚠️ Exercice '\(exerciseName)' (base: '\(baseName)') non trouvé dans le cache")
        return baseName.lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }
    
    // Nouvelle fonction pour extraire le nom de base d'un exercice
    private func extractBaseExerciseName(from exerciseName: String) -> String {
        // Supprimer les paramètres communs : distances (200m, 500m) et répétitions (10 reps)
        var baseName = exerciseName
        
        // Supprimer les patterns de distance : " 200m", " 500m", etc.
        baseName = baseName.replacingOccurrences(
            of: #" \d+m"#, 
            with: "", 
            options: .regularExpression
        )
        
        // Supprimer les patterns de répétitions : " 10 reps", " 20 reps", etc.
        baseName = baseName.replacingOccurrences(
            of: #" \d+ reps?"#, 
            with: "", 
            options: .regularExpression
        )
        
        // Supprimer les espaces en trop
        baseName = baseName.trimmingCharacters(in: .whitespaces)
        
        print("🔍 Extraction nom de base: '\(exerciseName)' -> '\(baseName)'")
        return baseName
    }
    
    private func convertWorkoutToUpdateRequest(_ workout: Workout) -> UpdateWorkoutRequest {
        let exercises = workout.performances.map { exercise in
            UpdateWorkoutExerciseRequest(
                id: exercise.id.uuidString.lowercased(), // Forcer minuscules pour PostgreSQL
                repsCompleted: exercise.repetitions > 0 ? exercise.repetitions : nil,
                durationCompleted: exercise.duration > 0 ? Int(exercise.duration) : nil,
                distanceCompleted: exercise.distance > 0 ? exercise.distance : nil,
                weightUsed: nil,
                restTime: nil,
                notes: nil,
                completedAt: exercise.completedAt?.iso8601String
            )
        }
        
        return UpdateWorkoutRequest(
            completedAt: workout.completedAt?.iso8601String,
            totalDuration: workout.totalDuration > 0 ? Int(workout.totalDuration) : nil,
            notes: nil,
            rating: nil,
            exercises: exercises
        )
    }
}

// MARK: - Date Extension for ISO8601

extension Date {
    var iso8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }
}

// MARK: - Mock Repository for Testing

class MockWorkoutRepository: WorkoutRepositoryProtocol {
    var shouldFail = false
    var mockWorkouts: [APIWorkout] = []
    
    func fetchWorkouts() async throws -> [APIWorkout] {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return mockWorkouts
    }
    
    func createWorkout(_ request: CreateWorkoutRequest) async throws -> APIWorkout {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return APIWorkout(
            id: UUID().uuidString,
            name: request.name,
            startedAt: request.startedAt,
            completedAt: nil,
            totalDuration: nil,
            notes: nil,
            rating: nil,
            templateId: request.templateId,
            template: nil,
            exercises: []
        )
    }
    
    func updateWorkout(workoutId: UUID, _ request: UpdateWorkoutRequest) async throws -> APIWorkout {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return mockWorkouts.first ?? APIWorkout(
            id: workoutId.uuidString,
            name: "Mock Workout",
            startedAt: Date().iso8601String,
            completedAt: request.completedAt,
            totalDuration: request.totalDuration,
            notes: request.notes,
            rating: request.rating,
            templateId: nil,
            template: nil,
            exercises: []
        )
    }
    
    func deleteWorkout(workoutId: UUID) async throws {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
    }
    
    func fetchPersonalBests() async throws -> [APIPersonalBest] {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
        return []
    }
    
    func syncWorkoutsWithCache() async throws {
        // Mock implementation - no-op
    }
    
    func getCachedWorkouts() -> [Workout] {
        return []
    }
    
    func getCachedWorkout(id: UUID) -> Workout? {
        return nil
    }
    
    func saveWorkoutLocally(_ workout: Workout) throws {
        // Mock implementation - no-op
    }
    
    func syncCompletedWorkout(_ workout: Workout) async throws {
        if shouldFail { throw APIError.networkError(NSError(domain: "Mock", code: 0)) }
    }
} 