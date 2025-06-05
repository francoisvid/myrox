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
        
        // Recherche exacte d'abord
        if let exercise = apiExercises.first(where: { 
            $0.name.lowercased() == normalizedName 
        }) {
            return exercise.id
        }
        
        // Recherche sans espaces
        let nameWithoutSpaces = normalizedName.replacingOccurrences(of: " ", with: "")
        if let exercise = apiExercises.first(where: { 
            $0.name.lowercased().replacingOccurrences(of: " ", with: "") == nameWithoutSpaces 
        }) {
            return exercise.id
        }
        
        // Recherche partielle (contient le nom)
        if let exercise = apiExercises.first(where: { 
            $0.name.lowercased().contains(normalizedName) || 
            normalizedName.contains($0.name.lowercased())
        }) {
            return exercise.id
        }
        
        // Mappages manuels pour les exercices avec des noms différents
        let manualMappings: [String: String] = [
            // Course / Running
            "course 1km": "1km Run",
            "run 1km": "1km Run",
            "1km run": "1km Run",
            "course": "1km Run",
            "running": "1km Run",
            
            // Rowing
            "rowing 1000m": "1000m Row",
            "1000m row": "1000m Row",
            "rowing": "1000m Row",
            "row": "1000m Row",
            
            // SkiErg
            "skierg 1000m": "1000m SkiErg",
            "1000m skierg": "1000m SkiErg",
            "skierg": "1000m SkiErg",
            "ski erg": "1000m SkiErg",
            
            // Wall Balls
            "wall balls": "75/100 Wall Balls",
            "wallballs": "75/100 Wall Balls",
            "wall ball": "75/100 Wall Balls",
            
            // Burpees
            "burpees broad jumps": "80m Burpee Broad Jumps",
            "burpee broad jumps": "80m Burpee Broad Jumps",
            "burpees": "80m Burpee Broad Jumps",
            "burpee": "80m Burpee Broad Jumps",
            
            // Farmers Carry
            "farmers carry": "200m Farmers Carry",
            "farmer carry": "200m Farmers Carry",
            "farmers": "200m Farmers Carry",
            
            // Sled
            "sled push": "50m Sled Push",
            "sledpush": "50m Sled Push",
            "sled pull": "50m Sled Pull",
            "sledpull": "50m Sled Pull",
            "sled": "50m Sled Push", // Default to push
            
            // Sandbag
            "sandbag lunges": "100m Sandbag Lunges",
            "sandbag": "100m Sandbag Lunges",
            "lunges": "100m Sandbag Lunges",
            
            // Functional exercises
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
        
        // Vérifier les mappages manuels
        if let mappedName = manualMappings[normalizedName] {
            return apiExercises.first(where: { $0.name == mappedName })?.id
        }
        
        // Pas trouvé
        print("⚠️ ExerciseMapper: Exercice '\(exerciseName)' non trouvé dans l'API")
        return nil
    }
    
    /// Convertit les exercices d'un template iOS vers les exercices API
    func mapTemplateExercises(_ templateExercises: [TemplateExercise]) -> [CreateTemplateExerciseRequest] {
        print("🔄 ExerciseMapper: Début mapping de \(templateExercises.count) exercices iOS")
        print("🔄 ExerciseMapper: Exercices API disponibles : \(apiExercises.count)")
        
        // Debug : afficher les exercices iOS à mapper
        for exercise in templateExercises {
            print("📝 Exercice iOS à mapper: '\(exercise.exerciseName)' (ordre: \(exercise.order))")
        }
        
        // Debug : afficher quelques exercices API disponibles
        if apiExercises.count > 0 {
            print("📋 Premiers exercices API disponibles:")
            for exercise in apiExercises.prefix(5) {
                print("   - '\(exercise.name)' (id: \(exercise.id))")
            }
        }
        
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