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
            HeartRatePoint.self
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
        let descriptor = FetchDescriptor<Exercise>()
        let existingExercises = try mainContext.fetch(descriptor)
        
        // Si le catalogue existe déjà et qu'on ne force pas la réinitialisation, on ne fait rien
        guard existingExercises.isEmpty || force else { return }
        
        // Si on force la réinitialisation, on supprime les exercices existants
        if force {
            for exercise in existingExercises {
                mainContext.delete(exercise)
            }
            try mainContext.save()
        }
        
        // Créer le catalogue d'exercices HYROX
        // (name, category, hasDistance, hasReps, distance, reps, description, tempsEstimé)
        let hyroxExercises = [
            // 8 Exercices officiels HYROX avec valeurs de compétition
            ("SkiErg", "Cardio", true, false, 1000.0, 0, "1000m sur la machine SkiErg", 180),
            ("Sled Push", "Force", true, false, 50.0, 0, "50m de poussée de traîneau", 240),
            ("Sled Pull", "Force", true, false, 50.0, 0, "50m de traction de traîneau", 240),
            ("Burpees Broad Jump", "Plyo", false, true, 0.0, 80, "80 burpees avec saut en longueur", 300),
            ("RowErg", "Cardio", true, false, 1000.0, 0, "1000m sur rameur", 180),
            ("Farmers Carry", "Force", true, false, 200.0, 0, "200m de transport de poids", 240),
            ("Sandbag Lunges", "Force", true, false, 200.0, 0, "200m de fentes avec sac de sable", 300),
            ("Wall Balls", "Force", false, true, 0.0, 100, "100 répétitions de wall balls", 210),
            
            // Exercices d'entraînement supplémentaires
            ("1 km Run", "Cardio", true, false, 1000.0, 0, "Course de 1 kilomètre", nil),
            ("Assault Bike", "Cardio", false, false, 0.0, 0, "Exercice sur Assault Bike", nil),
            ("Jump Rope", "Cardio", false, false, 0.0, 0, "Exercice de corde à sauter", nil),
            ("Sprint Intervals", "Cardio", false, false, 0.0, 0, "Intervalles de sprint", nil),
            ("High Knees", "Cardio", false, false, 0.0, 0, "Exercice de genoux hauts", nil),
            ("Mountain Climbers", "Cardio", false, false, 0.0, 0, "Exercice de grimpeurs", nil),
            ("Bear Crawl", "Cardio", false, false, 0.0, 0, "Exercice de déplacement en ours", nil),
            ("Battle Ropes", "Cardio", false, false, 0.0, 0, "Exercice avec cordes ondulatoires", nil),
            
            // Force
            ("Deadlifts", "Force", false, false, 0.0, 0, "Soulevés de terre", nil),
            ("Dumbbell Thrusters", "Force", false, false, 0.0, 0, "Thrusters avec haltères", nil),
            ("Dumbbell Snatch", "Force", false, false, 0.0, 0, "Arraché avec haltère", nil),
            ("Kettlebell Snatches", "Force", false, false, 0.0, 0, "Arrachés avec kettlebell", nil),
            ("Kettlebell Cleans", "Force", false, false, 0.0, 0, "Clean avec kettlebell", nil),
            ("Kettlebell Goblet Squats", "Force", false, false, 0.0, 0, "Squats goblet avec kettlebell", nil),
            ("Sandbag Cleans", "Force", false, false, 0.0, 0, "Clean avec sac de sable", nil),
            ("Sandbag Shouldering", "Force", false, false, 0.0, 0, "Portage de sac de sable sur l'épaule", nil),
            ("Weighted Lunges", "Force", false, false, 0.0, 0, "Fentes avec poids", nil),
            ("Box Step Overs", "Force", false, false, 0.0, 0, "Montées sur caisse", nil),
            ("Overhead Carry", "Force", false, false, 0.0, 0, "Transport en position overhead", nil),
            ("Med Ball Slams", "Force", false, false, 0.0, 0, "Lancers de médecine ball", nil),
            ("Push-ups", "Force", false, false, 0.0, 0, "Pompes", nil),
            ("Wall Sit", "Force", false, false, 0.0, 0, "Position assise contre un mur", nil),
            
            // Core
            ("Plank Hold", "Core", false, false, 0.0, 0, "Gainage en planche", nil),
            ("Sit-ups", "Core", false, false, 0.0, 0, "Redressements assis", nil),
            ("Russian Twists", "Core", false, false, 0.0, 0, "Rotations russes", nil),
            ("Hanging Knee Raises", "Core", false, false, 0.0, 0, "Élévations de genoux suspendu", nil),
            ("Toes to Bar", "Core", false, false, 0.0, 0, "Orteils à la barre", nil),
            ("Standing Pallof Press", "Core", false, false, 0.0, 0, "Press Pallof debout", nil),
            ("Air Squats", "Core", false, false, 0.0, 0, "Squats au poids du corps", nil),
            
            // Plyo
            ("Box Jumps", "Plyo", false, false, 0.0, 0, "Sauts sur caisse", nil),
            ("Broad Jumps", "Plyo", false, false, 0.0, 0, "Sauts en longueur", nil),
            ("Jumping Lunges", "Plyo", false, false, 0.0, 0, "Fentes sautées", nil),
            ("Burpees", "Plyo", false, false, 0.0, 0, "Burpees classiques", nil),
            ("Lateral Hops", "Plyo", false, false, 0.0, 0, "Sauts latéraux", nil)
        ]
        
        for (name, category, hasDistance, hasReps, distance, reps, _, _) in hyroxExercises {
            let exercise = Exercise(name: name, category: category)
            exercise.hasDistance = hasDistance
            exercise.hasRepetitions = hasReps
            exercise.standardDistance = distance
            exercise.standardRepetitions = reps
            mainContext.insert(exercise)
        }
        
        try mainContext.save()
    }
    
    // MARK: - Reset Catalog
    func resetExerciseCatalog() async throws {
        try await initializeExerciseCatalog(force: true)
    }
}
