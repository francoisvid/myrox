import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Bindable var exercise: WorkoutExercise
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var duration: TimeInterval = 0
    @State private var distance: Double = 0
    @State private var repetitions: Int = 0
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    @State private var timer: Timer?

    // Ajoute le modelContext pour accéder aux données SwiftData
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(exercise.exerciseName)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 30)

                Text(duration.formattedWithMilliseconds)
                    .font(.system(size: 70, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                timerControls
                inputFields
                Spacer()

                Button {
                    completeExercise()
                } label: {
                    Text("TERMINER L'EXERCICE")
                        .primaryButtonStyle()
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
        }
        .onAppear {
            duration = exercise.duration
            distance = exercise.distance
            repetitions = exercise.repetitions
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var timerControls: some View {
        HStack(spacing: 40) {
            Button {
                toggleTimer()
            } label: {
                Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(isTimerRunning ? Color.red : Color.green)
                    .clipShape(Circle())
            }

            Button {
                resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.yellow)
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private var inputFields: some View {
        VStack(spacing: 20) {
            if let exerciseDef = fetchExerciseDef() {
                if exerciseDef.hasDistance {
                    HStack {
                        Label("Distance", systemImage: "ruler").foregroundColor(.gray)
                        Spacer()
                        TextField("0", value: $distance, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("m").foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                if exerciseDef.hasRepetitions {
                    HStack {
                        Label("Répétitions", systemImage: "repeat").foregroundColor(.gray)
                        Spacer()
                        TextField("0", value: $repetitions, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("reps").foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }

    private func fetchExerciseDef() -> Exercise? {
        let name = exercise.exerciseName
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.name == name }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func toggleTimer() {
        if isTimerRunning {
            isTimerRunning = false
            timer?.invalidate()
        } else {
            isTimerRunning = true
            timerStartTime = Date().addingTimeInterval(-duration)
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                if let startTime = timerStartTime {
                    duration = Date().timeIntervalSince(startTime)
                }
            }
        }
    }

    private func resetTimer() {
        isTimerRunning = false
        timer?.invalidate()
        duration = 0
        timerStartTime = nil
    }

    private func completeExercise() {
        timer?.invalidate()
        viewModel.completeExercise(
            exercise,
            duration: duration,
            distance: distance,
            repetitions: repetitions
        )
        dismiss()
    }
}
