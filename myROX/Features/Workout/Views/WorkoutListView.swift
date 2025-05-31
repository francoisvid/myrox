import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var showingNewWorkoutSheet = false
    @State private var showingActiveWorkout = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingEditSheet = false
    
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
            .background(Color.adaptiveGradient)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Entraînements")
            .toolbar {
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
                get: { selectedTemplate != nil && showingEditSheet },
                set: { if !$0 { showingEditSheet = false } }
            )) {
                if let template = selectedTemplate, let vm = viewModel {
                    CreateTemplateView(viewModel: vm, editingTemplate: template)
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
                .foregroundColor(Color(.label))
            
            Text("Créez votre premier modèle d'entraînement")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button {
                showingNewWorkoutSheet = true
            } label: {
                Text("Créer un entraînement")
                    .primaryButtonStyle()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var templateGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 15),
            GridItem(.flexible(), spacing: 15),
        ], spacing: 20) {
            if let templates = viewModel?.templates {
                ForEach(templates) { template in
                    WorkoutTemplateCard(
                        template: template,
                        isActive: viewModel?.activeWorkout?.templateID == template.id,
                        onStart: {
                            selectedTemplate = template
                            viewModel?.startWorkout(from: template)
                            showingActiveWorkout = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                showingActiveWorkout = true
                            }
                        },
                        onDelete: {
                            viewModel?.deleteTemplate(template)
                        },
                        onEdit: {
                            selectedTemplate = template
                            showingEditSheet = true
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 20)
    }
    
    private var toolbarButtons: some View {
        HStack(spacing: 15) {
            Menu {
                Button {
                    viewModel?.cleanupLegacyTemplates()
                } label: {
                    Label("Nettoyer les anciens templates", systemImage: "arrow.clockwise.circle")
                }
                
                Divider()
                
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
