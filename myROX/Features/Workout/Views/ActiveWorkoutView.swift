import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let template: WorkoutTemplate
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: WorkoutExercise?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer Header
                timerHeader
                
                // Progress Bar
                progressBar
                
                // Exercise List
                if let workout = viewModel.activeWorkout, !workout.performances.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(workout.performances.prefix(3)) { exercise in
                            WorkoutExerciseRow(
                                exercise: exercise,
                                isNext: viewModel.isNextExercise(exercise),
                                onTap: {
                                    selectedExercise = exercise
                                }
                            )
                            .padding()
                            .background(Color(.systemGray6).opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("Aucun exercice pour cet entraînement.")
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .background(
                LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEndWorkoutAlert()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(
                    exercise: exercise,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private var timerHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.elapsedTime.formatted)
                .font(.system(size: 50, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .animation(.easeInOut(duration: 0.5), value: viewModel.elapsedTime)

            Text("Temps total")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
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
    
    private func showEndWorkoutAlert() {
        // Pour iOS 15+, on peut utiliser .alert avec des boutons personnalisés
        // Pour l'instant, on termine directement
        viewModel.endWorkout()
        dismiss()
    }
}
