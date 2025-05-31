import SwiftUI
import SwiftData

struct HyroxGoalsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseGoal.exerciseName) private var goals: [ExerciseGoal]
    @State private var editingGoal: String?
    @State private var newGoalMinutes: Double = 0
    
    // Les 8 exercices officiels HYROX
    private let hyroxOfficialExercises = [
        "SkiErg", "Sled Push", "Sled Pull", "Burpees Broad Jump",
        "RowErg", "Farmers Carry", "Sandbag Lunges", "Wall Balls"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.yellow)
                Text("Objectifs HYROX Compétition")
                    .font(.headline)
                    .foregroundColor(Color(.label))
            }
            
            Text("Temps cibles pour les 8 exercices officiels HYROX")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            ForEach(hyroxOfficialExercises, id: \.self) { exerciseName in
                let goal = goals.first { $0.exerciseName == exerciseName }
                let isEditing = editingGoal == exerciseName
                
                HyroxGoalRow(
                    exerciseName: exerciseName,
                    currentGoal: goal,
                    isEditing: isEditing,
                    newGoalMinutes: $newGoalMinutes,
                    onEdit: {
                        if isEditing {
                            saveGoal(for: exerciseName)
                        } else {
                            editingGoal = exerciseName
                            if let goal = goal {
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
        if let existingGoal = goals.first(where: { $0.exerciseName == exerciseName }) {
            existingGoal.targetTime = newGoalMinutes * 60
            existingGoal.updatedAt = Date()
        } else {
            let newGoal = ExerciseGoal(
                exerciseName: exerciseName,
                targetTime: newGoalMinutes * 60
            )
            modelContext.insert(newGoal)
        }
        
        try? modelContext.save()
        editingGoal = nil
        
        // Synchroniser avec la Watch
        DispatchQueue.main.async {
            WatchConnectivityService.shared.sendGoals()
        }
    }
}

struct HyroxGoalRow: View {
    let exerciseName: String
    let currentGoal: ExerciseGoal?
    let isEditing: Bool
    @Binding var newGoalMinutes: Double
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))
                
                // Afficher le temps standard/objectif selon le contexte
                if let goal = currentGoal, goal.targetTime > 0 {
                    Text("Objectif: \(goal.targetTime.formatted)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                } else {
                    Text("Aucun objectif défini")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Champ d'édition ou bouton
            if isEditing {
                HStack(spacing: 8) {
                    TextField("Minutes", value: $newGoalMinutes, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: onEdit) {
                Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
} 