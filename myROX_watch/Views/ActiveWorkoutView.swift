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
                            Text(exercise.name)
                                .font(.headline)
                            
                            // Afficher l'objectif
                            if let targetTime = dataService.goals[exercise.name], targetTime > 0 {
                                Text("Objectif: \(targetTime.formatted)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            
                            Text(viewModel.exerciseTimer.formatted)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundColor(.yellow)
                            
                            // Indicateur visuel si on dépasse l'objectif
                            if let targetTime = dataService.goals[exercise.name],
                               targetTime > 0 && viewModel.exerciseTimer > targetTime {
                                Text("Objectif dépassé!")
                                    .font(.caption)
                                    .foregroundColor(.red)
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
                        
                        // Stop workout
                        Button(role: .cancel) {
                            viewModel.finishWorkout()
                            dismiss()
                        } label: {
                            Label("Arrêter", systemImage: "stop.fill")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
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
}
