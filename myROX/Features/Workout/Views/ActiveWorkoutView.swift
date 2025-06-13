import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let template: WorkoutTemplate
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: WorkoutExercise?
    @State private var showEndWorkoutAlert = false
    @State private var showCancelWorkoutAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer Header
                timerHeader
                
                // Progress Bar
                progressBar
                
                // Exercise List
                exerciseList
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showCancelWorkoutAlert = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEndWorkoutAlert = true
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(
                    exercise: exercise,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $viewModel.showWorkoutCompletion) {
                if let completedWorkout = viewModel.completedWorkout {
                    WorkoutCompletionView(
                        workout: completedWorkout,
                        onComplete: {
                            // Nettoyer tous les états
                            viewModel.cleanupAfterWorkoutCompletion()
                            dismiss() // Fermer l'ActiveWorkoutView
                        }
                    )
                }
            }
            .alert("Terminer la séance", isPresented: $showEndWorkoutAlert) {
                Button("Continuer", role: .cancel) { }
                Button("Terminer", role: .destructive) {
                    viewModel.endWorkout()
                    // Ne pas fermer ici - la vue de fin de séance s'ouvrira automatiquement
                }
            } message: {
                Text("Êtes-vous sûr de vouloir terminer cette séance ?")
            }
            .alert("Annuler la séance", isPresented: $showCancelWorkoutAlert) {
                Button("Continuer", role: .cancel) { }
                Button("Annuler", role: .destructive) {
                    viewModel.cancelWorkout()
                    dismiss()
                }
            } message: {
                Text("Cette action annulera définitivement votre séance en cours. Aucune donnée ne sera sauvegardée.")
            }
        }
    }
    
    private var timerHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.elapsedTime.formatted)
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundColor(Color(.label))
            
            Text("Temps total")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 30)
    }
    
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progression")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(Int(viewModel.workoutProgress))%")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.yellow)
                        .frame(
                            width: geometry.size.width * (viewModel.workoutProgress / 100),
                            height: 8
                        )
                        .animation(.easeInOut, value: viewModel.workoutProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private var exerciseList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let workout = viewModel.activeWorkout {
                    // Grouper les exercices par round
                    let exercisesByRound = Dictionary(grouping: workout.performances) { $0.round }
                    let sortedRounds = exercisesByRound.keys.sorted()
                    
                    ForEach(sortedRounds, id: \.self) { round in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Round \(round)")
                                .font(.headline)
                                .foregroundColor(Color(.label))
                                .padding(.horizontal)
                            
                            if let roundExercises = exercisesByRound[round] {
                                ForEach(roundExercises.sorted(by: { $0.order < $1.order })) { exercise in
                                    WorkoutExerciseRow(
                                        exercise: exercise,
                                        isNext: viewModel.isNextExercise(exercise),
                                        onTap: {
                                            selectedExercise = exercise
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

