import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    let viewModel: WorkoutViewModel?
    let editingTemplate: WorkoutTemplate?
    
    @State private var templateName: String
    @State private var selectedExercises: [Exercise] = []
    @State private var showingExercisePicker = false
    @State private var rounds: Int
    
    init(viewModel: WorkoutViewModel?, editingTemplate: WorkoutTemplate? = nil) {
        self.viewModel = viewModel
        self.editingTemplate = editingTemplate
        _templateName = State(initialValue: editingTemplate?.name ?? "")
        _rounds = State(initialValue: editingTemplate?.rounds ?? 1)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Nom du template
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom de l'entraînement")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("Ex: HYROX Complet", text: $templateName)
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding()
                
                // Nombre de rounds
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombre de rounds")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button {
                            if rounds > 1 { rounds -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(rounds > 1 ? .yellow : .gray)
                        }
                        .disabled(rounds <= 1)
                        
                        Text("\(rounds)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(minWidth: 60)
                        
                        Button {
                            rounds += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                // Liste des exercices sélectionnés
                if selectedExercises.isEmpty {
                    emptyExerciseState
                } else {
                    selectedExercisesList
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Ajouter des exercices", systemImage: "plus.circle")
                            .secondaryButtonStyle()
                    }
                    
                    Button {
                        if let template = editingTemplate {
                            viewModel?.updateTemplate(
                                template,
                                name: templateName,
                                exerciseNames: selectedExercises.map { $0.name },
                                rounds: rounds
                            )
                        } else {
                            viewModel?.createTemplate(
                                name: templateName,
                                exerciseNames: selectedExercises.map { $0.name },
                                rounds: rounds
                            )
                        }
                        dismiss()
                    } label: {
                        Text(editingTemplate == nil ? "Créer l'entraînement" : "Mettre à jour")
                            .primaryButtonStyle()
                    }
                    .disabled(templateName.isEmpty || selectedExercises.isEmpty)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(editingTemplate == nil ? "Nouveau template" : "Modifier le template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(
                    exercises: exercises,
                    selectedExercises: $selectedExercises
                )
            }
            .onAppear {
                if let template = editingTemplate {
                    // Charger les exercices existants
                    let descriptor = FetchDescriptor<Exercise>()
                    if let allExercises = try? modelContext.fetch(descriptor) {
                        selectedExercises = template.exerciseNames.compactMap { name in
                            allExercises.first { $0.name == name }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyExerciseState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucun exercice sélectionné")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Ajoutez des exercices pour créer votre template")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var selectedExercisesList: some View {
        List {
            ForEach(selectedExercises) { exercise in
                ExerciseListItem(
                    exercise: exercise,
                    position: selectedExercises.firstIndex(of: exercise)! + 1,
                    onRemove: {
                        withAnimation {
                            if let index = selectedExercises.firstIndex(of: exercise) {
                                selectedExercises.remove(at: index)
                            }
                        }
                    }
                )
                .listRowBackground(Color.clear)
            }
            .onMove { from, to in
                selectedExercises.move(fromOffsets: from, toOffset: to)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    let exercises: [Exercise]
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    @State private var tempSelection: Set<Exercise> = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(exercises) { exercise in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                            
                            HStack {
                                Label(exercise.category, systemImage: iconForCategory(exercise.category))
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                
                                if exercise.hasDistance {
                                    Text("• \(Int(exercise.standardDistance ?? 0))m")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                if exercise.hasRepetitions {
                                    Text("• \(Int(exercise.standardRepetitions ?? 0)) reps")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if tempSelection.contains(exercise) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if tempSelection.contains(exercise) {
                            tempSelection.remove(exercise)
                        } else {
                            tempSelection.insert(exercise)
                        }
                    }
                }
            }
            .navigationTitle("Choisir des exercices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Valider (\(tempSelection.count))") {
                        // CORRECTION ICI : On remplace au lieu d'ajouter
                        selectedExercises = Array(tempSelection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(tempSelection.isEmpty)
                }
            }
        }
        .onAppear {
            // On initialise avec les exercices déjà sélectionnés
            tempSelection = Set(selectedExercises)
        }
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

// MARK: - Exercise List Item

struct ExerciseListItem: View {
    let exercise: Exercise
    let position: Int
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(position)")
                .font(.headline)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Label(exercise.category, systemImage: iconForCategory(exercise.category))
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    if exercise.hasDistance {
                        Text("\(Int(exercise.standardDistance ?? 0))m")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if exercise.hasRepetitions {
                        Text("\(Int(exercise.standardRepetitions ?? 0)) reps")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    CreateTemplateView(viewModel: WorkoutViewModel(modelContext: ModelContainer.shared.container.mainContext))
        .modelContainer(ModelContainer.shared.container)
}
