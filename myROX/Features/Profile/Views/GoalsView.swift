import SwiftUI
import SwiftData

struct GoalsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseGoal.exerciseName) private var goals: [ExerciseGoal]
    @State private var editingGoal: String?
    @State private var newGoalMinutes: Double = 0
    @State private var newGoalDistance: Double = 0
    @State private var newGoalReps: Int = 0
    @State private var showDetails = false
    
    private var sortedExercises: [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectifs HYROX")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            ForEach(Array(sortedExercises.prefix(showDetails ? sortedExercises.count : 5))) { exercise in
                let goal = goals.first { $0.exerciseName == exercise.name }
                let isEditing = editingGoal == exercise.name
                
                GoalRow(
                    exercise: exercise,
                    currentGoal: goal,
                    isEditing: isEditing,
                    newGoalMinutes: $newGoalMinutes,
                    newGoalDistance: $newGoalDistance,
                    newGoalReps: $newGoalReps,
                    onEdit: {
                        if isEditing {
                            saveGoal(for: exercise.name)
                        } else {
                            editingGoal = exercise.name
                            if let goal = goal {
                                newGoalMinutes = goal.targetTime / 60
                            } else {
                                newGoalMinutes = 0
                            }
                        }
                    }
                )
            }
            
            // Toggle pour les détails
            if sortedExercises.count > 5 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetails.toggle()
                    }
                } label: {
                    HStack {
                        Text(showDetails ? "Masquer les détails" : "Voir les détails")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    
    private func saveGoal(for exerciseName: String) {
        if let existingGoal = goals.first(where: { $0.exerciseName == exerciseName }) {
            existingGoal.targetTime = newGoalMinutes * 60
            existingGoal.targetDistance = newGoalDistance > 0 ? newGoalDistance : nil
            existingGoal.targetRepetitions = newGoalReps > 0 ? newGoalReps : nil
            existingGoal.updatedAt = Date()
        } else {
            let newGoal = ExerciseGoal(
                exerciseName: exerciseName,
                targetTime: newGoalMinutes * 60,
                targetDistance: newGoalDistance > 0 ? newGoalDistance : nil,
                targetRepetitions: newGoalReps > 0 ? newGoalReps : nil
            )
            modelContext.insert(newGoal)
        }
        
        try? modelContext.save()
        editingGoal = nil
        
        // Synchroniser avec la Watch
        // WatchConnectivityService.shared.sendGoals()
        
        // Synchroniser avec la Watch
        DispatchQueue.main.async {
            WatchConnectivityService.shared.sendGoals()
        }
    }
}

struct GoalRow: View {
    let exercise: Exercise
    let currentGoal: ExerciseGoal?
    let isEditing: Bool
    @Binding var newGoalMinutes: Double
    @Binding var newGoalDistance: Double
    @Binding var newGoalReps: Int
    let onEdit: () -> Void
    
    @State private var goalType: GoalType = .time
    
    enum GoalType: String, CaseIterable {
        case time = "Temps"
        case distance = "Distance"
        case reps = "Répétitions"
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(exercise.name)
                    .font(.subheadline)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                if isEditing {
                    Picker("Type", selection: $goalType) {
                        if true { // Toujours afficher temps
                            Text("Temps").tag(GoalType.time)
                        }
                        if exercise.hasDistance {
                            Text("Distance").tag(GoalType.distance)
                        }
                        if exercise.hasRepetitions {
                            Text("Reps").tag(GoalType.reps)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                } else {
                    if let goal = currentGoal {
                        VStack(alignment: .trailing, spacing: 4) {
                            if goal.targetTime > 0 {
                                Text("⏱ < \(goal.targetTime.formatted)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            if let distance = goal.targetDistance, distance > 0 {
                                Text("📏 > \(Int(distance))m")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            if let reps = goal.targetRepetitions, reps > 0 {
                                Text("🔄 > \(reps)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    } else {
                        Text("--")
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
            // Champs d'édition
            if isEditing {
                HStack {
                    switch goalType {
                    case .time:
                        TextField("Minutes", value: $newGoalMinutes, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("min")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                    case .distance:
                        TextField("Mètres", value: $newGoalDistance, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("m")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                    case .reps:
                        TextField("Répétitions", value: $newGoalReps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("reps")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
