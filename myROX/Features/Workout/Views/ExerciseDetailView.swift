import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Bindable var exercise: WorkoutExercise
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Query private var goals: [ExerciseGoal]
    @Query private var personalBests: [PersonalBest]

    @State private var duration: TimeInterval = 0
    @State private var distance: Double = 0
    @State private var repetitions: Int = 0
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    @State private var timer: Timer?

    // Ajoute le modelContext pour accéder aux données SwiftData
    @Environment(\.modelContext) private var modelContext

    // Durée cible : prioritaire celle portée par l'exercice (issue du template), sinon objectif défini par l'utilisateur
    private var displayedTargetTime: TimeInterval? {
        if let exerciseTarget = exercise.targetDuration { return exerciseTarget }
        return goals.first(where: { $0.exerciseName == exercise.exerciseName })?.targetTime
    }

    private var personalBest: PersonalBest? {
        let exerciseType = exercise.personalBestExerciseType
        return personalBests.first { $0.exerciseType == exerciseType }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(exercise.exerciseName)
                    .font(.largeTitle.bold())
                    .foregroundColor(Color(.label))
                    .padding(.top, 30)

                // Afficher les paramètres à effectuer
                if exercise.distance > 0 || exercise.repetitions > 0 || (exercise.targetDuration ?? 0) > 0 {
                    HStack(spacing: 16) {
                        if exercise.distance > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "ruler")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Text("\(Int(exercise.distance))m")
                                    .font(.title2.bold())
                                    .foregroundColor(.blue)
                            }
                        }

                        if exercise.repetitions > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Text("\(exercise.repetitions) reps")
                                    .font(.title2.bold())
                                    .foregroundColor(.green)
                            }
                        }

                        if let target = exercise.targetDuration, target > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                Text(formatTime(target))
                                    .font(.title2.bold())
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Afficher l'objectif et le PR
                VStack(spacing: 8) {
                    if let pb = personalBest {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                            Text("Record: \(pb.value.formatted)")
                                .foregroundColor(.yellow)
                        }
                        .font(.headline)
                    }
                }

                // Timer avec indicateur visuel
                ZStack {
                    Text(duration.formatted)
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                        .foregroundColor(timerColor)

                    // Cercle de progression si objectif défini
                    if let target = displayedTargetTime, target > 0 {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 200, height: 200)

                        Circle()
                            .trim(from: 0, to: min(1, duration / target))
                            .stroke(
                                duration > target ? Color.orange : Color.yellow,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear, value: duration)
                            .padding(20)
                    }
                }

                // Messages de statut
                VStack(spacing: 4) {
                    // Nouveau record
                    if let pb = personalBest, duration > 0 && duration < pb.value {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Nouveau record ! (\(pb.value.formatted) -> \(duration.formatted))")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }

                    // Objectif dépassé
                    if let target = displayedTargetTime, target > 0 && duration > target {
                        Text("Objectif dépassé de \((duration - target).formatted)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

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
            .background(Color.adaptiveGradient)
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
            print("[DEBUG] ExerciseDetailView - exerciseName: \(exercise.exerciseName)")
            print("[DEBUG] ExerciseDetailView - distance: \(exercise.distance)")
            print("[DEBUG] ExerciseDetailView - repetitions: \(exercise.repetitions)")
            print("[DEBUG] ExerciseDetailView - duration: \(exercise.duration)")
            print("[DEBUG] ExerciseDetailView - completedAt: \(String(describing: exercise.completedAt))")
            print("[DEBUG] ExerciseDetailView - averageHeartRate: \(exercise.averageHeartRate)")
            print("[DEBUG] ExerciseDetailView - maxHeartRate: \(exercise.maxHeartRate)")
            print("[DEBUG] ExerciseDetailView - round: \(exercise.round)")
            print("[DEBUG] ExerciseDetailView - order: \(exercise.order)")
            print("[DEBUG] ExerciseDetailView - isPersonalRecord: \(exercise.isPersonalRecord)")
            print("[DEBUG] ExerciseDetailView - workout: \(String(describing: exercise.workout))")
            print("[DEBUG] ExerciseDetailView - heartRatePoints: \(exercise.heartRatePoints)")
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var timerColor: Color {
        // Priorité: nouveau record (jaune) > objectif dépassé (orange) > normal
        if let pb = personalBest, duration > 0 && duration < pb.value {
            return .yellow  // Nouveau record !
        } else if let target = displayedTargetTime, target > 0 && duration > target {
            return .orange  // Objectif dépassé
        } else {
            return Color(.label)  // Normal
        }
    }

    private var timerControls: some View {
        HStack(spacing: 40) {
            Button {
                toggleTimer()
            } label: {
                Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(Color(.label))
                    .frame(width: 60, height: 60)
                    .background(isTimerRunning ? Color.red : Color.green)
                    .clipShape(Circle())
            }

            Button {
                resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title)
                    .foregroundColor(Color(.label))
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
                            .foregroundColor(Color(.label))
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
                            .foregroundColor(Color(.label))
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
