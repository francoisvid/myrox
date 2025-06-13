import SwiftData
import SwiftUI

actor ModelContainer {
    static let shared = ModelContainer()
    
    let container: SwiftData.ModelContainer
    let mainContext: ModelContext
    
    init() {
        let schema = Schema([
            Exercise.self,
            ExerciseGoal.self,
            ExerciseDefaults.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            Workout.self,
            WorkoutExercise.self,
            HeartRatePoint.self,
            PersonalBest.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // On ajoutera CloudKit plus tard si besoin
        )
        
        do {
            container = try SwiftData.ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            mainContext = ModelContext(container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Exercise Catalog
    func initializeExerciseCatalog(force: Bool = false) async throws {
        // Plus de chargement automatique du catalogue en dur
        // La synchronisation avec l'API se charge de récupérer les exercices
        print("📋 ModelContainer: Initialisation du catalogue - délégation à ExerciseSyncService")
    }
    
    // MARK: - Reset Catalog
    func resetExerciseCatalog() async throws {
        let descriptor = FetchDescriptor<Exercise>()
        let existingExercises = try mainContext.fetch(descriptor)
        
        // Supprimer tous les exercices existants
        for exercise in existingExercises {
            mainContext.delete(exercise)
        }
        
        try mainContext.save()
        print("🗑️ ModelContainer: Catalogue d'exercices réinitialisé (supprimé)")
    }
}
