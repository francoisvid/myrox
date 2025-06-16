import SwiftUI
import SwiftData

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let isNext: Bool
    let onTap: () -> Void

    @Query private var goals: [ExerciseGoal]
    @Query private var personalBests: [PersonalBest]

    // Durée cible prioritaire : celle définie dans l'exercice, sinon depuis les goals
    private var displayedTargetTime: TimeInterval? {
        if let exerciseTarget = exercise.targetDuration { return exerciseTarget }
        return goals.first(where: { $0.exerciseName == exercise.exerciseName })?.targetTime
    }

    private var personalBest: PersonalBest? {
        let exerciseType = exercise.personalBestExerciseType
        return personalBests.first { $0.exerciseType == exerciseType }
    }

    private var hasAchievedGoal: Bool {
        guard let target = displayedTargetTime, target > 0, exercise.duration > 0 else { return false }
        return exercise.duration <= target
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 32, height: 32)

                    statusIcon
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(exercise.completedAt != nil ? .black : .white)
                }

                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    // Nom de l'exercice
                    Text(exercise.exerciseName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.label))

                    // Distance et répétitions à effectuer + Personal Best
                    VStack(alignment: .leading, spacing: 2) {
                        // Paramètres de l'exercice (distance/reps à effectuer)
                        HStack(spacing: 12) {
                            if exercise.distance > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "ruler")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("\(Int(exercise.distance))m")
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                }
                            }

                            if exercise.repetitions > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("\(exercise.repetitions) reps")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                }
                            }

                            // Durée cible (objectif) si disponible et aucune distance/reps
                            if let target = displayedTargetTime, target > 0, exercise.distance == 0 && exercise.repetitions == 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text(formatTime(target))
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                }
                            }
                        }

                        // Personal Best et Objectif
                        HStack(spacing: 12) {
                            // Personal Best (toujours affiché s'il existe)
                            if let pb = personalBest {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    Text("PR: \(pb.value.formatted)")
                                        .font(.caption.bold())
                                        .foregroundColor(.yellow)
                                }
                            }

//                            // Objectif (affiché en plus du PR)
//                            if let target = displayedTargetTime, target > 0 {
//                                HStack(spacing: 4) {
//                                    Image(systemName: "target")
//                                        .font(.caption)
//                                        .foregroundColor(.blue)
//                                    Text("Obj: \(target.formatted)")
//                                        .font(.caption.bold())
//                                        .foregroundColor(.blue)
//                                }
//                            }
                        }
                    }

                    // Stats si complété
                    if exercise.completedAt != nil {
                        HStack(spacing: 16) {
                            // Durée avec indicateur d'objectif
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text(exercise.duration.formatted)
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                if displayedTargetTime != nil {
                                    Image(systemName: hasAchievedGoal ? "checkmark.circle.fill" : "xmark.circle")
                                        .font(.caption)
                                        .foregroundColor(hasAchievedGoal ? .green : .orange)
                                }
                            }

                            // Distance
                            if exercise.distance > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "ruler")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(Int(exercise.distance))m")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Répétitions
                            if exercise.repetitions > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(exercise.repetitions)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        Text(isNext ? "Appuyez pour commencer" : "En attente")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundStyle)
            .overlay(overlayBorder)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        if exercise.completedAt != nil {
            return hasAchievedGoal || displayedTargetTime == nil ? .green : .orange
        } else if isNext {
            return .yellow
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if exercise.completedAt != nil {
            Image(systemName: "checkmark")
        } else if isNext {
            Image(systemName: "play.fill")
        } else {
            Text("\(exercise.exerciseName.prefix(1))")
                .font(.caption)
        }
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isNext ? Color.yellow.opacity(0.15) : Color(.systemGray6))
    }

    private var overlayBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isNext ? Color.yellow : Color.clear, lineWidth: 2)
    }

    // Helper
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
