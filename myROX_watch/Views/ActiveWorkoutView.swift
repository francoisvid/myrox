import SwiftUICore
import SwiftUI

struct ActiveWorkoutView: View {
    @StateObject private var viewModel = WatchWorkoutViewModel()
    @EnvironmentObject var dataService: WatchDataService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if let workout = dataService.activeWorkout {
                ScrollView {
                    VStack(spacing: 15) {
                        // Progress
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                        
                        // Current exercise
                        if let exercise = viewModel.currentExercise {
                            CurrentExerciseView(exercise: exercise, viewModel: viewModel, dataService: dataService)
                        } else {
                            Text("Aucun exercice disponible")
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                            .frame(height: 10)
                        
                        // Workout Actions
                        WorkoutActionsView(viewModel: viewModel, dismiss: dismiss)
                    }
                    .padding(.horizontal, 20)
                }
                .navigationTitle(viewModel.currentExercise?.round != nil ? "Round \(viewModel.currentExercise!.round)" : "Workout")
                .navigationBarBackButtonHidden(true)
                .padding(.horizontal, 20)
            } else {
                VStack {
                    Text("Workout terminé")
                        .font(.headline)
                    Text("Retour à l'accueil...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .onAppear {
                    // Attendre un court instant avant de revenir à l'accueil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            print("ActiveWorkoutView apparaît")
            print("Workout actif: \(String(describing: dataService.activeWorkout))")
            // Initialiser l'index au premier exercice non complété
            viewModel.initializeExerciseIndex()
            // Démarrer automatiquement le timer si un workout est actif
            if dataService.activeWorkout != nil && !viewModel.isTimerRunning {
                viewModel.startExerciseTimer()
            }
        }
    }
}

// MARK: - Current Exercise View
struct CurrentExerciseView: View {
    let exercise: WatchExercise
    @ObservedObject var viewModel: WatchWorkoutViewModel
    @ObservedObject var dataService: WatchDataService
    
    var body: some View {
        VStack(spacing: 4) {
            // Indicateur d'exercice complété
            HStack {
                Spacer()
                if exercise.isCompleted {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("Terminé")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Text(exercise.name)
                .font(.headline)
                .foregroundColor(exercise.isCompleted ? .gray : .white)
            
            // Afficher les paramètres de l'exercice
            ActiveExerciseParametersView(exercise: exercise)
            
            ExerciseGoalsView(exercise: exercise, dataService: dataService)
            
            Text(formatTime(viewModel.exerciseTimer))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(timerColor(for: exercise, dataService: dataService, viewModel: viewModel))
            
            ExerciseStatusView(exercise: exercise, dataService: dataService, viewModel: viewModel)
        }
        
        ExerciseControlsView(viewModel: viewModel)
    }
    
    // Helper pour formater le temps
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Helper pour la couleur du timer
    private func timerColor(for exercise: WatchExercise, dataService: WatchDataService, viewModel: WatchWorkoutViewModel) -> Color {
        // Priorité: nouveau record (jaune) > objectif dépassé (orange) > normal
        if let personalBest = dataService.personalBests.first(where: { $0.exerciseType == exercise.personalBestExerciseType }),
           viewModel.exerciseTimer > 0 && viewModel.exerciseTimer < personalBest.value {
            return .yellow  // Nouveau record !
        } else if let targetTime = dataService.goals[exercise.name],
                  targetTime > 0 && viewModel.exerciseTimer > targetTime {
            return .orange  // Objectif dépassé
        } else {
            return .white   // Normal (blanc sur Watch)
        }
    }
}



// MARK: - Exercise Goals View
struct ExerciseGoalsView: View {
    let exercise: WatchExercise
    @ObservedObject var dataService: WatchDataService
    
    var body: some View {
        VStack(spacing: 2) {
            if let targetTime = dataService.goals[exercise.name], targetTime > 0 {
                Text("Obj: \(formatTime(targetTime))")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if let personalBest = dataService.personalBests.first(where: { $0.exerciseType == exercise.personalBestExerciseType }) {
                HStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("PR: \(formatTime(personalBest.value))")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Exercise Status View
struct ExerciseStatusView: View {
    let exercise: WatchExercise
    @ObservedObject var dataService: WatchDataService
    @ObservedObject var viewModel: WatchWorkoutViewModel
    
    var body: some View {
        VStack(spacing: 2) {
            // Nouveau record
            if let personalBest = dataService.personalBests.first(where: { $0.exerciseType == exercise.personalBestExerciseType }),
               viewModel.exerciseTimer > 0 && viewModel.exerciseTimer < personalBest.value {
                Text("Nouveau record!")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            // Objectif dépassé
            if let targetTime = dataService.goals[exercise.name],
               targetTime > 0 && viewModel.exerciseTimer > targetTime {
                Text("Objectif dépassé!")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Exercise Controls View
struct ExerciseControlsView: View {
    @ObservedObject var viewModel: WatchWorkoutViewModel
    
    var body: some View {
        // Navigation controls
        HStack(spacing: 15) {
            Button {
                viewModel.previousExercise()
            } label: {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.canGoPrevious ? .blue : .gray)
            .disabled(!viewModel.canGoPrevious)
            
            Button {
                if viewModel.isTimerRunning {
                    viewModel.pauseExerciseTimer()
                } else {
                    viewModel.startExerciseTimer()
                }
            } label: {
                Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.isTimerRunning ? .red : .green)
            
            Button {
                viewModel.completeCurrentExercise()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundColor(.green)
            
            Button {
                viewModel.nextExercise()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.canGoNext ? .blue : .gray)
            .disabled(!viewModel.canGoNext)
        }
    }
}

// MARK: - Workout Actions View
struct WorkoutActionsView: View {
    @ObservedObject var viewModel: WatchWorkoutViewModel
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 8) {
            // Terminer le workout
            Button {
                viewModel.finishWorkout()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Terminer")
                    Spacer()
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(10)
                .frame(width: 130)
            }
            .buttonStyle(.plain)
            
            // Annuler le workout
            Button(role: .destructive) {
                viewModel.cancelWorkout()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Annuler")
                    Spacer()
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red)
                .foregroundColor(.black)
                .cornerRadius(10)
                .frame(width: 130)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Active Exercise Parameters View
struct ActiveExerciseParametersView: View {
    let exercise: WatchExercise
    
    // Helper pour formater la durée en mm:ss
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        if exercise.targetDistance != nil || exercise.targetRepetitions != nil || exercise.targetDuration != nil {
            HStack(spacing: 8) {
                if let distance = exercise.targetDistance, distance > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "ruler")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("\(Int(distance))m")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                if let reps = exercise.targetRepetitions, reps > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "repeat")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("\(reps) reps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                if let targetTime = exercise.targetDuration, targetTime > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text(formatTime(targetTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
        }
    }
}
