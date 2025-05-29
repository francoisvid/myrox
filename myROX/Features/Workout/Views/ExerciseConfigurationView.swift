import SwiftUI
import SwiftData

struct ExerciseConfigurationView: View {
    let exercise: Exercise
    @Binding var templateExercises: [TemplateExercise]
    @Environment(\.dismiss) private var dismiss
    
    @State private var distance: Double = 0
    @State private var repetitions: Int = 0
    @State private var hasCustomDistance = false
    @State private var hasCustomRepetitions = false
    
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
                distanceConfiguration
            }
            
            if exercise.hasRepetitions {
                repetitionsConfiguration
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
    
    private var distanceConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Distance personnalisée", isOn: $hasCustomDistance)
                    .font(.subheadline)
            }
            
            if hasCustomDistance {
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
            } else if let standardDistance = exercise.standardDistance {
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var repetitionsConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Répétitions personnalisées", isOn: $hasCustomRepetitions)
                    .font(.subheadline)
            }
            
            if hasCustomRepetitions {
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
            } else if let standardReps = exercise.standardRepetitions {
                HStack {
                    Text("Répétitions standard :")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(standardReps) reps")
                        .font(.title3)
                        .foregroundColor(Color(.label))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var addButton: some View {
        Button {
            addExerciseToTemplate()
        } label: {
            Text("Ajouter à l'entraînement")
                .primaryButtonStyle()
        }
        .padding()
    }
    
    private func setupInitialValues() {
        if let standardDistance = exercise.standardDistance, standardDistance > 0 {
            distance = standardDistance
        }
        
        if let standardReps = exercise.standardRepetitions, standardReps > 0 {
            repetitions = standardReps
        }
    }
    
    private func addExerciseToTemplate() {
        let finalDistance = hasCustomDistance ? distance : exercise.standardDistance
        let finalRepetitions = hasCustomRepetitions ? repetitions : exercise.standardRepetitions
        
        let templateExercise = TemplateExercise(
            exerciseName: exercise.name,
            targetDistance: finalDistance,
            targetRepetitions: finalRepetitions,
            order: templateExercises.count
        )
        
        templateExercises.append(templateExercise)
        dismiss()
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