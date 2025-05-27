import SwiftUI
import SwiftData

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let isNext: Bool
    let onTap: () -> Void
    
    @Query private var goals: [ExerciseGoal]
    
    private var targetTime: TimeInterval? {
        goals.first(where: { $0.exerciseName == exercise.exerciseName })?.targetTime
    }
    
    private var hasAchievedGoal: Bool {
        guard let target = targetTime, target > 0, exercise.duration > 0 else { return false }
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
                    // Nom et objectif
                    HStack(spacing: 8) {
                        Text(exercise.exerciseName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        if let target = targetTime, target > 0 {
                            Text("Obj: \(target.formatted)")
                                .font(.caption)
                                .foregroundColor(.yellow.opacity(0.7))
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
                                
                                if targetTime != nil {
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
            return hasAchievedGoal || targetTime == nil ? .green : .orange
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
}
