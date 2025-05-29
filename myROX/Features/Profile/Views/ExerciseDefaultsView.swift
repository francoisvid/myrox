import SwiftUI
import SwiftData

struct ExerciseDefaultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \ExerciseDefaults.exerciseName) private var defaults: [ExerciseDefaults]
    
    @State private var editingExercise: String?
    @State private var newDistance: Double = 0
    @State private var newRepetitions: Int = 0
    @State private var searchText = ""
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header explicatif
                headerSection
                
                // Barre de recherche
                searchSection
                
                // Liste des exercices
                exercisesList
            }
            .padding()
            .background(Color(.systemBackground))
            .navigationTitle("Valeurs par défaut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Réinitialiser") {
                        resetAllDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                Text("Paramètres par défaut")
                    .font(.headline)
                    .foregroundColor(Color(.label))
            }
            
            Text("Modifiez les valeurs par défaut utilisées lors de la création de templates. Ces valeurs remplacent celles du catalogue d'exercices.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Rechercher un exercice...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredExercises) { exercise in
                    let exerciseDefaults = defaults.first { $0.exerciseName == exercise.name }
                    let isEditing = editingExercise == exercise.name
                    
                    ExerciseDefaultRow(
                        exercise: exercise,
                        currentDefaults: exerciseDefaults,
                        isEditing: isEditing,
                        newDistance: $newDistance,
                        newRepetitions: $newRepetitions,
                        onEdit: {
                            if isEditing {
                                saveDefaults(for: exercise)
                            } else {
                                startEditing(exercise, with: exerciseDefaults)
                            }
                        },
                        onReset: {
                            resetDefaults(for: exercise)
                        }
                    )
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    private func startEditing(_ exercise: Exercise, with currentDefaults: ExerciseDefaults?) {
        editingExercise = exercise.name
        
        if let defaults = currentDefaults {
            newDistance = defaults.defaultDistance ?? exercise.standardDistance ?? 0
            newRepetitions = defaults.defaultRepetitions ?? exercise.standardRepetitions ?? 0
        } else {
            newDistance = exercise.standardDistance ?? 0
            newRepetitions = exercise.standardRepetitions ?? 0
        }
    }
    
    private func saveDefaults(for exercise: Exercise) {
        if let existingDefaults = defaults.first(where: { $0.exerciseName == exercise.name }) {
            // Mettre à jour les valeurs existantes
            var hasChanges = false
            
            // Sauvegarder la distance si l'exercice l'autorise ou si on a une valeur > 0
            if exercise.hasDistance || newDistance > 0 {
                existingDefaults.defaultDistance = newDistance > 0 ? newDistance : nil
                hasChanges = true
            }
            
            // Sauvegarder les répétitions si l'exercice l'autorise ou si on a une valeur > 0  
            if exercise.hasRepetitions || newRepetitions > 0 {
                existingDefaults.defaultRepetitions = newRepetitions > 0 ? newRepetitions : nil
                hasChanges = true
            }
            
            if hasChanges {
                existingDefaults.isCustomized = true
                existingDefaults.updatedAt = Date()
            }
        } else {
            // Créer nouvelles valeurs par défaut seulement si on a des valeurs significatives
            let hasDistance = (exercise.hasDistance || newDistance > 0) && newDistance > 0
            let hasReps = (exercise.hasRepetitions || newRepetitions > 0) && newRepetitions > 0
            
            if hasDistance || hasReps {
                let newDefaults = ExerciseDefaults(
                    exerciseName: exercise.name,
                    defaultDistance: hasDistance ? newDistance : nil,
                    defaultRepetitions: hasReps ? newRepetitions : nil
                )
                newDefaults.isCustomized = true
                modelContext.insert(newDefaults)
            }
        }
        
        try? modelContext.save()
        editingExercise = nil
    }
    
    private func resetDefaults(for exercise: Exercise) {
        if let existingDefaults = defaults.first(where: { $0.exerciseName == exercise.name }) {
            // Supprimer complètement l'entrée personnalisée
            modelContext.delete(existingDefaults)
            try? modelContext.save()
        }
        editingExercise = nil
    }
    
    private func resetAllDefaults() {
        for defaultValue in defaults {
            modelContext.delete(defaultValue)
        }
        try? modelContext.save()
    }
}

struct ExerciseDefaultRow: View {
    let exercise: Exercise
    let currentDefaults: ExerciseDefaults?
    let isEditing: Bool
    @Binding var newDistance: Double
    @Binding var newRepetitions: Int
    let onEdit: () -> Void
    let onReset: () -> Void
    
    private var effectiveDistance: Double? {
        currentDefaults?.defaultDistance ?? exercise.standardDistance
    }
    
    private var effectiveRepetitions: Int? {
        currentDefaults?.defaultRepetitions ?? exercise.standardRepetitions
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header avec nom et catégorie
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline.bold())
                        .foregroundColor(Color(.label))
                    
                    HStack {
                        Label(exercise.category, systemImage: iconForCategory(exercise.category))
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        if currentDefaults?.isCustomized == true {
                            Label("Personnalisé", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Boutons d'action
                HStack(spacing: 8) {
                    if currentDefaults?.isCustomized == true {
                        Button(action: onReset) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button(action: onEdit) {
                        Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            // Valeurs actuelles ou champs d'édition
            if isEditing {
                editingFields
            } else {
                currentValues
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var currentValues: some View {
        HStack(spacing: 16) {
            // Afficher la distance si l'exercice a hasDistance OU si des valeurs personnalisées existent
            if exercise.hasDistance || (currentDefaults?.defaultDistance != nil && currentDefaults!.defaultDistance! > 0) {
                if let distance = effectiveDistance, distance > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(Int(distance))m")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Indicateur si c'est une valeur personnalisée
                        if currentDefaults?.defaultDistance != nil && currentDefaults?.isCustomized == true {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // Afficher les répétitions si l'exercice a hasRepetitions OU si des valeurs personnalisées existent
            if exercise.hasRepetitions || (currentDefaults?.defaultRepetitions != nil && currentDefaults!.defaultRepetitions! > 0) {
                if let reps = effectiveRepetitions, reps > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(reps) reps")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Indicateur si c'est une valeur personnalisée
                        if currentDefaults?.defaultRepetitions != nil && currentDefaults?.isCustomized == true {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // Afficher "Temps seulement" uniquement si aucune valeur n'est définie
            if !exercise.hasDistance && !exercise.hasRepetitions && 
               (currentDefaults?.defaultDistance == nil || currentDefaults!.defaultDistance! <= 0) &&
               (currentDefaults?.defaultRepetitions == nil || currentDefaults!.defaultRepetitions! <= 0) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Temps seulement")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
    
    private var editingFields: some View {
        VStack(spacing: 8) {
            // Permettre l'édition de la distance si l'exercice l'autorise OU si des valeurs personnalisées existent
            if exercise.hasDistance || (currentDefaults?.defaultDistance != nil) {
                HStack {
                    Text("Distance :")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    TextField("Distance", value: $newDistance, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    
                    Text("m")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Permettre l'édition des répétitions si l'exercice l'autorise OU si des valeurs personnalisées existent
            if exercise.hasRepetitions || (currentDefaults?.defaultRepetitions != nil) {
                HStack {
                    Text("Répétitions :")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    TextField("Reps", value: $newRepetitions, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    
                    Text("reps")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Section pour ajouter de nouveaux paramètres si l'exercice n'en a pas par défaut
            if !exercise.hasDistance && !exercise.hasRepetitions && currentDefaults == nil {
                VStack(spacing: 8) {
                    Text("Cet exercice utilise uniquement le temps par défaut")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Vous pouvez ajouter des paramètres personnalisés :")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Button {
                            newDistance = 100
                        } label: {
                            Label("Ajouter distance", systemImage: "ruler")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        Button {
                            newRepetitions = 10
                        } label: {
                            Label("Ajouter répétitions", systemImage: "repeat")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cardio": return "heart.fill"
        case "Force": return "dumbbell.fill"
        case "Plyo": return "figure.jumprope"
        case "Core": return "figure.strengthtraining.traditional"
        default: return "figure.strengthtraining.traditional"
        }
    }
} 