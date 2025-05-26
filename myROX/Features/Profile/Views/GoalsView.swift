import SwiftUI
import SwiftData

struct GoalsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseGoal.exerciseName) private var goals: [ExerciseGoal]
    @State private var editingGoal: String?
    @State private var newGoalMinutes: Double = 0
    
    private var sortedExercises: [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectifs HYROX")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(sortedExercises) { exercise in
                GoalRow(
                    exercise: exercise,
                    currentGoal: goals.first { $0.exerciseName == exercise.name },
                    isEditing: editingGoal == exercise.name,
                    newGoalMinutes: $newGoalMinutes,
                    onEdit: {
                        if editingGoal == exercise.name {
                            saveGoal(for: exercise.name)
                        } else {
                            editingGoal = exercise.name
                            if let goal = goals.first(where: { $0.exerciseName == exercise.name }) {
                                newGoalMinutes = goal.targetTime / 60
                            } else {
                                newGoalMinutes = 0
                            }
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func saveGoal(for exerciseName: String) {
        let targetTime = newGoalMinutes * 60
        
        if let existingGoal = goals.first(where: { $0.exerciseName == exerciseName }) {
            existingGoal.targetTime = targetTime
            existingGoal.updatedAt = Date()
        } else {
            let newGoal = ExerciseGoal(exerciseName: exerciseName, targetTime: targetTime)
            modelContext.insert(newGoal)
        }
        
        try? modelContext.save()
        editingGoal = nil
    }
}

struct GoalRow: View {
    let exercise: Exercise
    let currentGoal: ExerciseGoal?
    let isEditing: Bool
    @Binding var newGoalMinutes: Double
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Text(exercise.name)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            if isEditing {
                HStack(spacing: 4) {
                    TextField("Minutes", value: $newGoalMinutes, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                if let goal = currentGoal, goal.targetTime > 0 {
                    Text("< \(goal.targetTime.formatted)")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                } else {
                    Text("--:--")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: onEdit) {
                Image(systemName: isEditing ? "checkmark.circle" : "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
