import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    let viewModel: WorkoutViewModel?
    let editingTemplate: WorkoutTemplate?
    
    @State private var templateName: String
    @State private var templateExercises: [TemplateExercise] = []
    @State private var showingExercisePicker = false
    @State private var showingExerciseConfig = false
    @State private var selectedExerciseToConfig: Exercise?
    @State private var rounds: Int
    
    init(viewModel: WorkoutViewModel?, editingTemplate: WorkoutTemplate? = nil) {
        self.viewModel = viewModel
        self.editingTemplate = editingTemplate
        _templateName = State(initialValue: editingTemplate?.name ?? "")
        _rounds = State(initialValue: editingTemplate?.rounds ?? 1)
        
        // Initialiser la liste d'exercices - le chargement se fera dans onAppear
        _templateExercises = State(initialValue: [])
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Nom du template
                templateNameSection
                
                // Nombre de rounds
                roundsSection
                
                // Liste des exercices configurés
                if templateExercises.isEmpty {
                    emptyExerciseState
                } else {
                    configuredExercisesList
                }
                
                Spacer()
                
                // Boutons d'action
                actionButtons
            }
            .background(Color(.systemBackground))
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
                SimpleExercisePickerView(
                    exercises: exercises,
                    onExerciseSelected: { exercise in
                        selectedExerciseToConfig = exercise
                        showingExerciseConfig = true
                    }
                )
            }
            .sheet(isPresented: $showingExerciseConfig) {
                if let exercise = selectedExerciseToConfig {
                    ExerciseConfigurationView(
                        exercise: exercise,
                        templateExercises: $templateExercises
                    )
                }
            }
            .onAppear {
                loadExistingTemplate()
            }
        }
    }
    
    private var templateNameSection: some View {
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
    }
    
    private var roundsSection: some View {
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
                    .foregroundColor(Color(.label))
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
    }
    
    private var emptyExerciseState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucun exercice configuré")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Ajoutez des exercices avec leurs paramètres pour créer votre template")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var configuredExercisesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Exercices configurés")
                    .font(.headline)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                Text("\(templateExercises.count) exercice\(templateExercises.count > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            List {
                ForEach(templateExercises.sorted(by: { $0.order < $1.order }), id: \.id) { templateExercise in
                    TemplateExerciseRow(
                        templateExercise: templateExercise,
                        position: templateExercise.order + 1,
                        onRemove: {
                            removeTemplateExercise(templateExercise)
                        }
                    )
                    .listRowBackground(Color.clear)
                }
                .onMove { from, to in
                    moveExercises(from: from, to: to)
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingExercisePicker = true
            } label: {
                Label("Ajouter un exercice", systemImage: "plus.circle")
                    .secondaryButtonStyle()
            }
            
            Button {
                saveTemplate()
            } label: {
                Text(editingTemplate == nil ? "Créer l'entraînement" : "Mettre à jour")
                    .primaryButtonStyle()
            }
            .disabled(templateName.isEmpty || templateExercises.isEmpty)
        }
        .padding()
    }
    
    private func loadExistingTemplate() {
        guard let template = editingTemplate else { return }
        
        // Charger directement les exercices du template
        templateExercises = template.exercises.sorted(by: { $0.order < $1.order })
        print("Chargé \(templateExercises.count) exercices depuis le template")
    }
    
    private func removeTemplateExercise(_ templateExercise: TemplateExercise) {
        withAnimation {
            if let index = templateExercises.firstIndex(where: { $0.id == templateExercise.id }) {
                templateExercises.remove(at: index)
                // Réorganiser les ordres
                for i in 0..<templateExercises.count {
                    templateExercises[i].order = i
                }
            }
        }
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sortedExercises = templateExercises.sorted(by: { $0.order < $1.order })
        sortedExercises.move(fromOffsets: source, toOffset: destination)
        
        // Mettre à jour les ordres
        for (index, exercise) in sortedExercises.enumerated() {
            exercise.order = index
        }
        
        templateExercises = sortedExercises
    }
    
    private func saveTemplate() {
        if let template = editingTemplate {
            viewModel?.updateTemplate(
                template,
                name: templateName,
                exercises: templateExercises,
                rounds: rounds
            )
        } else {
            viewModel?.createTemplate(
                name: templateName,
                exercises: templateExercises,
                rounds: rounds
            )
        }
        dismiss()
    }
}

// MARK: - Template Exercise Row

struct TemplateExerciseRow: View {
    let templateExercise: TemplateExercise
    let position: Int
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(position)")
                .font(.headline)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(templateExercise.exerciseName)
                    .font(.headline)
                    .foregroundColor(Color(.label))
                
                // Affichage détaillé des paramètres
                TemplateExerciseParametersDisplay(templateExercise: templateExercise)
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
        .background(Color(.systemBackground))
        .shadow(
            color: .black.opacity(0.15),
            radius: 6,
            x: 0,
            y: 3
        )
        .cornerRadius(12)
    }
}

// MARK: - Template Exercise Parameters Display
struct TemplateExerciseParametersDisplay: View {
    let templateExercise: TemplateExercise
    
    var body: some View {
        HStack(spacing: 12) {
            if let distance = templateExercise.targetDistance, distance > 0 {
                DistanceParameterBadge(distance: distance)
            }
            
            if let reps = templateExercise.targetRepetitions, reps > 0 {
                RepetitionsParameterBadge(repetitions: reps)
            }
            
            if templateExercise.targetDistance == nil && templateExercise.targetRepetitions == nil {
                TimeOnlyParameterBadge()
            }
        }
    }
}

// MARK: - Parameter Badges for Template Exercises
struct DistanceParameterBadge: View {
    let distance: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "ruler")
                .font(.caption)
                .foregroundColor(.blue)
            Text("\(Int(distance))m")
                .font(.caption.bold())
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
}

struct RepetitionsParameterBadge: View {
    let repetitions: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
                .font(.caption)
                .foregroundColor(.green)
            Text("\(repetitions) reps")
                .font(.caption.bold())
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
    }
}

struct TimeOnlyParameterBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.orange)
            Text("Temps seulement")
                .font(.caption.bold())
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Simple Exercise Picker

struct SimpleExercisePickerView: View {
    let exercises: [Exercise]
    let onExerciseSelected: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: String = "Tous"
    
    private let categories = ["Tous", "Cardio", "Force", "Core", "Plyo"]
    
    private var filteredExercises: [Exercise] {
        var filtered = exercises
        
        // Filtrer par catégorie
        if selectedCategory != "Tous" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filtrer par recherche
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche
                searchSection
                
                // Sélecteur de catégorie
                categorySection
                
                // Liste des exercices
                exercisesList
            }
            .navigationTitle("Choisir un exercice")
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
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Rechercher un exercice...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 10)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if category != "Tous" {
                                Image(systemName: iconForCategory(category))
                                    .font(.caption)
                            }
                            
                            Text(category)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedCategory == category ? Color.yellow : Color(.systemGray5)
                        )
                        .foregroundColor(
                            selectedCategory == category ? .black : Color(.label)
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var exercisesList: some View {
        List {
            if filteredExercises.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Aucun exercice trouvé")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Essayez un autre terme de recherche")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredExercises) { exercise in
                    ExerciseListItem(
                        exercise: exercise,
                        onSelect: {
                            onExerciseSelected(exercise)
                            dismiss()
                        }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cardio": return "heart.fill"
        case "Force": return "dumbbell.fill"
        case "Plyo": return "figure.jumprope"
        case "Core": return "figure.strengthtraining.traditional"
        default: return "list.bullet"
        }
    }
}

// MARK: - Exercise List Item
struct ExerciseListItem: View {
    let exercise: Exercise
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                    
                    ExerciseInfoRow(exercise: exercise)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Info Row
struct ExerciseInfoRow: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            Label(exercise.category, systemImage: iconForCategory(exercise.category))
                .font(.caption)
                .foregroundColor(.yellow)
            
            if exercise.hasDistance, let distance = exercise.standardDistance {
                Text("• \(Int(distance))m")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if exercise.hasRepetitions, let reps = exercise.standardRepetitions {
                Text("• \(reps) reps")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
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

#Preview {
    CreateTemplateView(viewModel: WorkoutViewModel(modelContext: ModelContainer.shared.container.mainContext))
        .modelContainer(ModelContainer.shared.container)
}
