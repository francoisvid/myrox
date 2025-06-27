import Foundation

// MARK: - Exercise Mapper Service
@MainActor
class ExerciseMapper: ObservableObject {
    
    static let shared = ExerciseMapper()
    
    @Published private var apiExercises: [APIExercise] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Load Exercises from API
    
    func loadExercises() async {
        guard apiExercises.isEmpty else { 
            print("📋 ExerciseMapper: Exercices déjà chargés (\(apiExercises.count) exercices)")
            return 
        }
        
        print("🔄 ExerciseMapper: Début chargement des exercices depuis l'API...")
        isLoading = true
        error = nil
        
        do {
            let exercises = try await apiService.fetchExercises()
            apiExercises = exercises
            print("✅ ExerciseMapper: \(exercises.count) exercices chargés avec succès")
            
            // Debug : afficher les types d'exercices chargés
            let hyroxCount = exercises.filter { $0.isHyroxExercise }.count
            let functionalCount = exercises.filter { !$0.isHyroxExercise }.count
            print("📊 ExerciseMapper: \(hyroxCount) exercices HYROX, \(functionalCount) exercices fonctionnels")
            
        } catch {
            self.error = error
            print("❌ ExerciseMapper: Erreur chargement exercices - \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Mapping Methods
    
    /// Convertit un nom d'exercice iOS vers un ID d'exercice API
    func mapExerciseNameToAPIId(_ exerciseName: String) -> String? {
        // Normaliser le nom pour la recherche (case insensitive, sans espaces)
        let normalizedName = exerciseName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 ExerciseMapper: Recherche de '\(exerciseName)' (normalisé: '\(normalizedName)')")
        
        // 1. Recherche exacte d'abord
        if let exercise = apiExercises.first(where: { 
            $0.name.lowercased() == normalizedName 
        }) {
            print("✅ ExerciseMapper: Match exact trouvé - '\(exerciseName)' -> '\(exercise.name)' (ID: \(exercise.id))")
            return exercise.id
        }
        
        // 2. Recherche sans espaces
        let nameWithoutSpaces = normalizedName.replacingOccurrences(of: " ", with: "")
        if let exercise = apiExercises.first(where: { 
            $0.name.lowercased().replacingOccurrences(of: " ", with: "") == nameWithoutSpaces 
        }) {
            print("✅ ExerciseMapper: Match sans espaces trouvé - '\(exerciseName)' -> '\(exercise.name)' (ID: \(exercise.id))")
            return exercise.id
        }
        
        // 3. Mappages explicites pour les variations d'écriture SEULEMENT
        let basicMappings: [String: String] = [
            // Course / Running (base)
            "course": "Run",
            "running": "Run",
            
            // Rowing (base)
            "rowing": "RowErg",
            "row": "RowErg",
            
            // SkiErg (base)
            "ski erg": "SkiErg",
            
            // Exercices fonctionnels
            "air squats": "Air Squats",
            "squats": "Air Squats",
            "air squat": "Air Squats",
            "squat": "Air Squats",
            
            "pull-ups": "Pull-ups",
            "pullups": "Pull-ups", 
            "pull up": "Pull-ups",
            "pullup": "Pull-ups",
            
            "push-ups": "Push-ups",
            "pushups": "Push-ups",
            "push up": "Push-ups",
            "pushup": "Push-ups"
        ]
        
        // Vérifier les mappages explicites
        if let mappedName = basicMappings[normalizedName] {
            if let exercise = apiExercises.first(where: { $0.name == mappedName }) {
                print("✅ ExerciseMapper: Match via mapping explicite - '\(exerciseName)' -> '\(exercise.name)' (ID: \(exercise.id))")
                return exercise.id
            }
        }
        
        // 4. SUPPRIMÉ : La recherche partielle trop permissive qui causait le problème
        // Cette recherche causait que "burpees" matchait "burpees broad jump"
        
        // Pas trouvé - lister les exercices disponibles pour debug
        print("❌ ExerciseMapper: Exercice '\(exerciseName)' non trouvé dans l'API")
        print("📋 ExerciseMapper: Exercices disponibles contenant 'burpees':")
        for exercise in apiExercises.filter({ $0.name.lowercased().contains("burpees") }) {
            print("   - '\(exercise.name)' (ID: \(exercise.id), HYROX: \(exercise.isHyroxExercise))")
        }
        
        return nil
    }
    
    /// Convertit les exercices d'un template iOS vers les exercices API
    func mapTemplateExercises(_ templateExercises: [TemplateExercise]) -> [CreateTemplateExerciseRequest] {
        print("🔄 ExerciseMapper: Début mapping de \(templateExercises.count) exercices iOS")
        print("🔄 ExerciseMapper: Exercices API disponibles : \(apiExercises.count)")
        
        let mappedExercises: [CreateTemplateExerciseRequest] = templateExercises.compactMap { templateExercise -> CreateTemplateExerciseRequest? in
            print("🔍 Tentative mapping: '\(templateExercise.exerciseName)'")
            
            guard let exerciseId = mapExerciseNameToAPIId(templateExercise.exerciseName) else {
                print("❌ ExerciseMapper: Impossible de mapper l'exercice '\(templateExercise.exerciseName)'")
                return nil
            }
            
            print("✅ ExerciseMapper: Exercice mappé '\(templateExercise.exerciseName)' -> \(exerciseId)")
            
            // Convertir les types pour correspondre à l'API
            let targetDistanceInt = templateExercise.targetDistance.map { Int($0) }
            
            return CreateTemplateExerciseRequest(
                exerciseId: exerciseId,
                order: templateExercise.order,
                targetRepetitions: templateExercise.targetRepetitions == 0 ? nil : templateExercise.targetRepetitions,
                targetDistance: targetDistanceInt,
                targetTime: nil, // À implémenter si nécessaire
                restTime: nil    // À implémenter si nécessaire
            )
        }
        
        print("🎯 ExerciseMapper: Résultat final - \(mappedExercises.count)/\(templateExercises.count) exercices mappés")
        return mappedExercises
    }
    
    // MARK: - Convenience Methods
    
    var availableExercises: [APIExercise] {
        apiExercises
    }
    
    var hyroxExercises: [APIExercise] {
        apiExercises.filter { $0.isHyroxExercise }
    }
    
    var functionalExercises: [APIExercise] {
        apiExercises.filter { !$0.isHyroxExercise }
    }
} 