import SwiftUICore
import SwiftData
import SwiftUI

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let isActive: Bool
    let onStart: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var exercises: [Exercise] = []
    @State private var showDeleteAlert = false
    @Query private var goals: [ExerciseGoal]
    
    private var sortedTemplateExercises: [TemplateExercise] {
        template.exercises.sorted(by: { $0.order < $1.order })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button {
                            onEdit()
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.yellow)
                        }
                        
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    Label("\(sortedTemplateExercises.count)", systemImage: "figure.strengthtraining.traditional")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    
                    Label("\(template.rounds)", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple)
                        .clipShape(Capsule())
                    
                    if isActive {
                        Text("EN COURS")
                            .font(.caption2.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Exercise list preview with parameters
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(sortedTemplateExercises.prefix(4).enumerated()), id: \.element.id) { index, templateExercise in
                    TemplateExercisePreviewRow(
                        templateExercise: templateExercise,
                        index: index,
                        exercises: exercises,
                        goals: goals
                    )
                }
                
                if sortedTemplateExercises.count > 4 {
                    HStack {
                        Text("...")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .frame(width: 20, alignment: .leading)
                        
                        Text("et \(sortedTemplateExercises.count - 4) autre\(sortedTemplateExercises.count - 4 > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                }
            }
            .frame(minHeight: 120, alignment: .top)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5).opacity(0.6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            
            // Start button
            Button(action: onStart) {
                HStack {
                    Image(systemName: isActive ? "eye.fill" : "play.fill")
                    Text(isActive ? "VOIR" : "DÉMARRER")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isActive ? Color.gray : Color.yellow)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color.yellow : Color.clear, lineWidth: 2)
        )
//        .shadow(
//            color: isActive ? .yellow.opacity(0.4) : .black.opacity(0.15),
//            radius: isActive ? 12 : 6,
//            x: 0,
//            y: isActive ? 6 : 3
//        )
        .onAppear {
            loadExercises()
        }
        .alert("Supprimer l'entraînement", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cet entraînement ?")
        }
    }
    
    private func loadExercises() {
        let descriptor = FetchDescriptor<Exercise>()
        exercises = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cardio": return "heart.fill"
        case "Force": return "dumbbell.fill"
        case "Plyo": return "figure.jumprope"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Template Exercise Preview Row
struct TemplateExercisePreviewRow: View {
    let templateExercise: TemplateExercise
    let index: Int
    let exercises: [Exercise]
    let goals: [ExerciseGoal]
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(templateExercise.exerciseName)
                    .font(.caption.bold())
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                
                // Paramètres en ligne
                ExerciseParametersView(templateExercise: templateExercise)
            }
            
            Spacer()
            
            // Objectif et catégorie
            ExerciseGoalAndCategoryView(
                templateExercise: templateExercise,
                exercises: exercises,
                goals: goals
            )
        }
    }
}

// MARK: - Exercise Parameters View
struct ExerciseParametersView: View {
    let templateExercise: TemplateExercise
    
    var body: some View {
        HStack(spacing: 8) {
            if let distance = templateExercise.targetDistance, distance > 0 {
                DistanceBadge(distance: distance)
            }
            
            if let reps = templateExercise.targetRepetitions, reps > 0 {
                RepetitionsBadge(repetitions: reps)
            }
            
            if templateExercise.targetDistance == nil && templateExercise.targetRepetitions == nil {
                TimeBadge()
            }
        }
    }
}

// MARK: - Parameter Badges
struct DistanceBadge: View {
    let distance: Double
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "ruler")
                .font(.caption2)
                .foregroundColor(.blue)
            Text("\(Int(distance))m")
                .font(.caption2.bold())
                .foregroundColor(.blue)
        }
    }
}

struct RepetitionsBadge: View {
    let repetitions: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "repeat")
                .font(.caption2)
                .foregroundColor(.green)
            Text("\(repetitions)")
                .font(.caption2.bold())
                .foregroundColor(.green)
        }
    }
}

struct TimeBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(.orange)
            Text("temps")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Exercise Goal and Category View
struct ExerciseGoalAndCategoryView: View {
    let templateExercise: TemplateExercise
    let exercises: [Exercise]
    let goals: [ExerciseGoal]
    
    var body: some View {
        HStack(spacing: 8) {
            if let goal = goals.first(where: { $0.exerciseName == templateExercise.exerciseName }),
               goal.targetTime > 0 {
                Text("< \(goal.targetTime.formatted)")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
            
            if let exercise = exercises.first(where: { $0.name == templateExercise.exerciseName }) {
                Image(systemName: iconForCategory(exercise.category))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cardio": return "heart.fill"
        case "Force": return "dumbbell.fill"
        case "Plyo": return "figure.jumprope"
        default: return "figure.strengthtraining.traditional"
        }
    }
}
