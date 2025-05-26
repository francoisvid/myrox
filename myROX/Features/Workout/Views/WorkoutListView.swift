import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var showingNewWorkoutSheet = false
    @State private var showingActiveWorkout = false
    @State private var selectedTemplate: WorkoutTemplate?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let vm = viewModel {
                    if vm.templates.isEmpty {
                        emptyStateView
                    } else {
                        templateGrid
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Entraînements")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            .sheet(isPresented: $showingNewWorkoutSheet) {
                if let vm = viewModel {
                    CreateTemplateView(viewModel: vm)
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.activeWorkout != nil && showingActiveWorkout },
                set: { if !$0 { showingActiveWorkout = false } }
            )) {
                if let template = selectedTemplate, let vm = viewModel, vm.activeWorkout != nil {
                    ActiveWorkoutView(template: template, viewModel: vm)
                }
            }
            .sheet(isPresented: $showingActiveWorkout) {
                if let template = selectedTemplate, let vm = viewModel {
                    ActiveWorkoutView(template: template, viewModel: vm)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = WorkoutViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Aucun entraînement")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Créez votre premier modèle d'entraînement")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button {
                showingNewWorkoutSheet = true
            } label: {
                Text("Créer un entraînement")
                    .primaryButtonStyle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var templateGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 15),
            GridItem(.flexible(), spacing: 15)
        ], spacing: 20) {
            if let templates = viewModel?.templates {
                ForEach(templates) { template in
                    WorkoutTemplateCard(
                        template: template,
                        isActive: viewModel?.activeWorkout?.templateID == template.id
                    ) {
                        selectedTemplate = template
                        viewModel?.startWorkout(from: template)
                        showingActiveWorkout = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            showingActiveWorkout = true
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 20)
    }
    
    private var toolbarButtons: some View {
        HStack(spacing: 15) {
            Menu {
                Button(role: .destructive) {
                    viewModel?.deleteAllTemplates()
                } label: {
                    Label("Supprimer tous les entraînements", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            
            Button {
                showingNewWorkoutSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
            }
        }
    }
}

#Preview {
    WorkoutListView()
        .modelContainer(ModelContainer.shared.container)
}
