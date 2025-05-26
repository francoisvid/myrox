import SwiftUI

struct ActiveWorkoutViewWatch: View {
    @StateObject private var viewModel = WatchWorkoutViewModel()
    @EnvironmentObject var dataService: WatchDataService
    
    var body: some View {
        if let workout = dataService.activeWorkout {
            VStack {
                // Progress
                ProgressView(value: viewModel.progress) {
                    Text("Progression")
                        .font(.caption)
                }
                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                .padding()
                
                // Current exercise
                if let exercise = viewModel.currentExercise {
                    Text(exercise.name)
                        .font(.headline)
                        .padding(.bottom)
                    
                    Text(viewModel.exerciseTimer.formatted)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                    
                    // Controls
                    HStack {
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
                    }
                }
                
                // Stop workout
                Button {
                    dataService.endWorkoutSession()
                } label: {
                    Label("Arrêter", systemImage: "stop.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(.top)
            }
            .navigationTitle("Workout")
            .navigationBarBackButtonHidden(true)
        }
    }
}
