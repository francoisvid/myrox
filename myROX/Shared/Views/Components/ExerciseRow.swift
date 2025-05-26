import SwiftUI

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let isNext: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(exercise.completedAt != nil ? Color.green : (isNext ? Color.yellow : Color.gray.opacity(0.3)))
                        .frame(width: 30, height: 30)
                    
                    if exercise.completedAt != nil {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.black)
                    } else if isNext {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                            .foregroundColor(.black)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if exercise.completedAt != nil {
                        HStack(spacing: 12) {
                            if exercise.duration > 0 {
                                Label(exercise.duration.formatted, systemImage: "timer")
                            }
                            if exercise.distance > 0 {
                                Label("\(Int(exercise.distance))m", systemImage: "ruler")
                            }
                            if exercise.repetitions > 0 {
                                Label("\(exercise.repetitions)", systemImage: "repeat")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isNext ? Color.yellow.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isNext ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
