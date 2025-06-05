import SwiftUI
import SwiftData

struct ExerciseConfigurationView: View {
    let exercise: Exercise
    @Binding var templateExercises: [TemplateExercise]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseDefaults.exerciseName) private var exerciseDefaults: [ExerciseDefaults]
    
    @State private var distance: Double = 0
    @State private var repetitions: Int = 0
    @State private var hasCustomDistance = false
    @State private var hasCustomRepetitions = false
    @State private var showSavedMessage = false
    
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
            
            // Distance - toujours afficher si hasDistance OU si on veut permettre la saisie
            if exercise.hasDistance || hasCustomDistance {
                DistanceConfigurationSection(
                    exercise: exercise,
                    effectiveDistance: effectiveDistance,
                    hasCustomDistance: $hasCustomDistance,
                    distance: $distance
                )
            }
            
            // Répétitions - toujours afficher si hasRepetitions OU si on veut permettre la saisie  
            if exercise.hasRepetitions || hasCustomRepetitions {
                RepetitionsConfigurationSection(
                    exercise: exercise,
                    effectiveRepetitions: effectiveRepetitions,
                    hasCustomRepetitions: $hasCustomRepetitions,
                    repetitions: $repetitions
                )
            }
            
            // Section pour ajouter des paramètres si aucun n'est configuré
            if !exercise.hasDistance && !exercise.hasRepetitions && !hasCustomDistance && !hasCustomRepetitions {
                VStack(alignment: .leading, spacing: 12) {
                    // Afficher les valeurs par défaut existantes s'il y en a
                    if let effDist = effectiveDistance, effDist > 0 {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.blue)
                            Text("Distance par défaut :")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(effDist)) m")
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                            
                            Button {
                                hasCustomDistance = true
                                distance = effDist
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if let effReps = effectiveRepetitions, effReps > 0 {
                        HStack {
                            Image(systemName: "repeat")
                                .foregroundColor(.green)
                            Text("Répétitions par défaut :")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(effReps) reps")
                                .font(.title3.bold())
                                .foregroundColor(.green)
                            
                            Button {
                                hasCustomRepetitions = true
                                repetitions = effReps
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Message principal
                    if effectiveDistance == nil && effectiveRepetitions == nil {
                        Text("Cet exercice se base uniquement sur le temps par défaut")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Vous pouvez ajouter des paramètres personnalisés :")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Valeurs par défaut configurées • Tapez ✏️ pour modifier ou ajoutez d'autres paramètres :")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Boutons pour ajouter des paramètres supplémentaires
                    HStack(spacing: 12) {
                        if effectiveDistance == nil {
                            Button {
                                hasCustomDistance = true
                                distance = 100 // Valeur par défaut raisonnable
                            } label: {
                                Label("Ajouter distance", systemImage: "ruler")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if effectiveRepetitions == nil {
                            Button {
                                hasCustomRepetitions = true
                                repetitions = 10 // Valeur par défaut raisonnable
                            } label: {
                                Label("Ajouter répétitions", systemImage: "repeat")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
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
            
            // Message de confirmation si valeurs sauvegardées
            if showSavedMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Valeurs sauvegardées comme nouvelles valeurs par défaut")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
                .transition(.opacity)
            }
            
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
        
        // Sauvegarder les nouvelles valeurs comme défaut si elles ont été personnalisées
        let wasSaved = saveAsDefaults(distance: finalDistance, repetitions: finalRepetitions)
        
        // Créer et ajouter l'exercice au template
        let nextOrder = templateExercises.map(\.order).max().map { $0 + 1 } ?? 0
        let templateExercise = TemplateExercise(
            exerciseName: exercise.name,
            targetDistance: finalDistance,
            targetRepetitions: finalRepetitions,
            order: nextOrder
        )
        
        templateExercises.append(templateExercise)
        
        // Afficher le message de confirmation si des valeurs ont été sauvegardées
        if wasSaved {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSavedMessage = true
            }
            
            // Masquer le message après 1.5 secondes puis fermer
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSavedMessage = false
                }
                
                // Fermer après l'animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        } else {
            // Pas de message, fermer directement
            dismiss()
        }
    }
    
    private func saveAsDefaults(distance: Double?, repetitions: Int?) -> Bool {
        // Détecter si on doit sauvegarder (valeurs différentes des standards OU toggles personnalisés activés)
        let shouldSaveDistance = (hasCustomDistance && distance != nil && distance! > 0) ||
                                (distance != nil && distance! > 0 && distance != exercise.standardDistance)
        
        let shouldSaveRepetitions = (hasCustomRepetitions && repetitions != nil && repetitions! > 0) ||
                                   (repetitions != nil && repetitions! > 0 && repetitions != exercise.standardRepetitions)
        
        // Ne sauvegarder que si on a des changements significatifs
        if shouldSaveDistance || shouldSaveRepetitions {
            // Chercher ou créer ExerciseDefaults
            if let existingDefaults = exerciseDefaults.first(where: { $0.exerciseName == exercise.name }) {
                // Mettre à jour les valeurs existantes
                var hasChanges = false
                
                if shouldSaveDistance {
                    existingDefaults.defaultDistance = distance
                    hasChanges = true
                }
                if shouldSaveRepetitions {
                    existingDefaults.defaultRepetitions = repetitions
                    hasChanges = true
                }
                
                if hasChanges {
                    existingDefaults.isCustomized = true
                    existingDefaults.updatedAt = Date()
                }
                
                print("✅ Mise à jour valeurs par défaut pour \(exercise.name): distance=\(distance ?? 0), reps=\(repetitions ?? 0)")
            } else {
                // Créer nouvelles valeurs par défaut
                let newDefaults = ExerciseDefaults(
                    exerciseName: exercise.name,
                    defaultDistance: shouldSaveDistance ? distance : nil,
                    defaultRepetitions: shouldSaveRepetitions ? repetitions : nil
                )
                newDefaults.isCustomized = true
                
                modelContext.insert(newDefaults)
                print("✅ Création nouvelles valeurs par défaut pour \(exercise.name): distance=\(distance ?? 0), reps=\(repetitions ?? 0)")
            }
            
            // Sauvegarder le contexte
            do {
                try modelContext.save()
                return true // Indique qu'une sauvegarde a eu lieu
            } catch {
                print("❌ Erreur lors de la sauvegarde des valeurs par défaut: \(error)")
                return false
            }
        }
        
        return false // Aucune sauvegarde nécessaire
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
                if exercise.hasDistance {
                    Toggle("Distance personnalisée", isOn: $hasCustomDistance)
                        .font(.subheadline)
                } else {
                    HStack {
                        Text("Distance personnalisée")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button {
                            hasCustomDistance = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            if hasCustomDistance {
                CustomDistanceInput(distance: $distance)
            } else if let standardDistance = effectiveDistance {
                StandardDistanceDisplay(standardDistance: standardDistance)
            } else if exercise.hasDistance {
                // Exercice qui devrait avoir une distance mais n'en a pas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aucune distance par défaut définie")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Activez 'Distance personnalisée' pour en définir une")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
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
                if exercise.hasRepetitions {
                    Toggle("Répétitions personnalisées", isOn: $hasCustomRepetitions)
                        .font(.subheadline)
                } else {
                    HStack {
                        Text("Répétitions personnalisées")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button {
                            hasCustomRepetitions = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            if hasCustomRepetitions {
                CustomRepetitionsInput(repetitions: $repetitions)
            } else if let standardReps = effectiveRepetitions {
                StandardRepetitionsDisplay(standardRepetitions: standardReps)
            } else if exercise.hasRepetitions {
                // Exercice qui devrait avoir des répétitions mais n'en a pas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aucune répétition par défaut définie")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Activez 'Répétitions personnalisées' pour en définir")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
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