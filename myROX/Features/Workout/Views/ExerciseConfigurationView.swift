import SwiftUI
import SwiftData

struct ExerciseConfigurationView: View {
    let exercise: Exercise
    @Binding var templateExercises: [TemplateExercise]
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExerciseDefaults.exerciseName) private var exerciseDefaults: [ExerciseDefaults]
    
    @State private var distance: Double = 0
    @State private var repetitions: Int = 0
    @State private var hasCustomDistance = false
    @State private var hasCustomRepetitions = false
    
    // Calculer les valeurs effectives (personnalisées ou standards)
    private var effectiveDistance: Double? {
        exerciseDefaults.first(where: { $0.exerciseName == exercise.name })?.defaultDistance ?? exercise.standardDistance
    }
    
    private var effectiveRepetitions: Int? {
        exerciseDefaults.first(where: { $0.exerciseName == exercise.name })?.defaultRepetitions ?? exercise.standardRepetitions
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // Header avec info exercice
                exerciseHeader
                
                // Configuration des paramètres
                parametersSection
                
                Spacer()
                
                // Bouton d'ajout
                addButton
            }
            .padding()
            .background(Color(.systemBackground))
            .navigationTitle("Configurer l'exercice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.title2.bold())
                .foregroundColor(Color(.label))
            
            HStack {
                Label(exercise.category, systemImage: iconForCategory(exercise.category))
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paramètres de l'exercice")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            if exercise.hasDistance {
                DistanceConfigurationSection(
                    exercise: exercise,
                    effectiveDistance: effectiveDistance,
                    hasCustomDistance: $hasCustomDistance,
                    distance: $distance
                )
            }
            
            if exercise.hasRepetitions {
                RepetitionsConfigurationSection(
                    exercise: exercise,
                    effectiveRepetitions: effectiveRepetitions,
                    hasCustomRepetitions: $hasCustomRepetitions,
                    repetitions: $repetitions
                )
            }
            
            if !exercise.hasDistance && !exercise.hasRepetitions {
                Text("Cet exercice se base uniquement sur le temps")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var addButton: some View {
        VStack(spacing: 12) {
            // Aperçu de ce qui sera ajouté
            HStack {
                Text("Aperçu :")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(getPreviewText())
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button {
                addExerciseToTemplate()
            } label: {
                Text("Ajouter à l'entraînement")
                    .primaryButtonStyle()
            }
        }
        .padding()
    }
    
    private func setupInitialValues() {
        if let distance = effectiveDistance, distance > 0 {
            self.distance = distance
        }
        
        if let reps = effectiveRepetitions, reps > 0 {
            repetitions = reps
        }
    }
    
    private func addExerciseToTemplate() {
        let finalDistance = hasCustomDistance ? distance : effectiveDistance
        let finalRepetitions = hasCustomRepetitions ? repetitions : effectiveRepetitions
        
        let templateExercise = TemplateExercise(
            exerciseName: exercise.name,
            targetDistance: finalDistance,
            targetRepetitions: finalRepetitions,
            order: templateExercises.count
        )
        
        templateExercises.append(templateExercise)
        dismiss()
    }
    
    private func getPreviewText() -> String {
        var components: [String] = [exercise.name]
        
        let finalDistance = hasCustomDistance ? distance : effectiveDistance
        let finalRepetitions = hasCustomRepetitions ? repetitions : effectiveRepetitions
        
        if let dist = finalDistance, dist > 0 {
            components.append("\(Int(dist))m")
        }
        
        if let reps = finalRepetitions, reps > 0 {
            components.append("\(reps) reps")
        }
        
        if finalDistance == nil && finalRepetitions == nil {
            components.append("temps seulement")
        }
        
        return components.joined(separator: " • ")
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cardio": return "heart.fill"
        case "Force": return "dumbbell.fill"
        case "Plyo": return "figure.jumprope"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Distance Configuration Section
struct DistanceConfigurationSection: View {
    let exercise: Exercise
    let effectiveDistance: Double?
    @Binding var hasCustomDistance: Bool
    @Binding var distance: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Distance personnalisée", isOn: $hasCustomDistance)
                    .font(.subheadline)
            }
            
            if hasCustomDistance {
                CustomDistanceInput(distance: $distance)
            } else if let standardDistance = effectiveDistance {
                StandardDistanceDisplay(standardDistance: standardDistance)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Repetitions Configuration Section
struct RepetitionsConfigurationSection: View {
    let exercise: Exercise
    let effectiveRepetitions: Int?
    @Binding var hasCustomRepetitions: Bool
    @Binding var repetitions: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Répétitions personnalisées", isOn: $hasCustomRepetitions)
                    .font(.subheadline)
            }
            
            if hasCustomRepetitions {
                CustomRepetitionsInput(repetitions: $repetitions)
            } else if let standardReps = effectiveRepetitions {
                StandardRepetitionsDisplay(standardRepetitions: standardReps)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Input Components
struct CustomDistanceInput: View {
    @Binding var distance: Double
    
    var body: some View {
        HStack {
            Text("Distance :")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            TextField("Distance", value: $distance, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.title3)
                .foregroundColor(Color(.label))
            
            Text("m")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct CustomRepetitionsInput: View {
    @Binding var repetitions: Int
    
    var body: some View {
        HStack {
            Text("Répétitions :")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            TextField("Reps", value: $repetitions, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.title3)
                .foregroundColor(Color(.label))
            
            Text("reps")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct StandardDistanceDisplay: View {
    let standardDistance: Double
    
    var body: some View {
        HStack {
            Text("Distance standard :")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text("\(Int(standardDistance)) m")
                .font(.title3)
                .foregroundColor(Color(.label))
        }
    }
}

struct StandardRepetitionsDisplay: View {
    let standardRepetitions: Int
    
    var body: some View {
        HStack {
            Text("Répétitions standard :")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text("\(standardRepetitions) reps")
                .font(.title3)
                .foregroundColor(Color(.label))
        }
    }
}

#Preview {
    let exercise = Exercise(name: "Running", category: "Cardio")
    exercise.hasDistance = true
    exercise.standardDistance = 1000
    
    @State var templateExercises: [TemplateExercise] = []
    
    return ExerciseConfigurationView(
        exercise: exercise,
        templateExercises: $templateExercises
    )
} 