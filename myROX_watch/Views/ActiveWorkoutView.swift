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
                        ProgressView(value: viewModel.progress) {
                            Text("Progression")
                                .font(.caption)
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                        .padding(.horizontal)
                        
                        // Current exercise
                        if let exercise = viewModel.currentExercise {
                            VStack(spacing: 8) {
                                Text("Round \(exercise.round)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(exercise.name)
                                    .font(.headline)
                                
                                // Afficher les paramètres de l'exercice
                                ActiveExerciseParametersView(exercise: exercise)
                                
                                // Afficher l'objectif et le PR
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
                                
                                Text(formatTime(viewModel.exerciseTimer))
                                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                                    .foregroundColor(timerColor(for: exercise))
                                
                                // Messages de statut
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
                            
                            // Controls
                            HStack(spacing: 20) {
                                Button {
                                    viewModel.previousExercise()
                                } label: {
                                    Image(systemName: "arrow.left.circle.fill")
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                                
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
                                .foregroundColor(.blue)
                            }
                        } else {
                            Text("Aucun exercice disponible")
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                            .frame(height: 10)
                        
                        // Workout Actions
                        VStack(spacing: 8) {
                            // Terminer le workout
                            Button {
                                viewModel.finishWorkout()
                                dismiss()
                            } label: {
                                Label("Terminer", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            
                            // Annuler le workout
                            Button(role: .destructive) {
                                viewModel.cancelWorkout()
                                dismiss()
                            } label: {
                                Label("Annuler", systemImage: "xmark.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .navigationTitle("Workout")
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
            // Démarrer automatiquement le timer si un workout est actif
            if dataService.activeWorkout != nil && !viewModel.isTimerRunning {
                viewModel.startExerciseTimer()
            }
        }
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
    private func timerColor(for exercise: WatchExercise) -> Color {
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
