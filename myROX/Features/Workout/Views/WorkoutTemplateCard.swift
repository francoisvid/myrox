import SwiftUICore
import SwiftData
import SwiftUI

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let isActive: Bool
    let onStart: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var exercises: [Exercise] = []
    @State private var showDeleteAlert = false
    @Query private var goals: [ExerciseGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                HStack(spacing: 8) {
                    Label("\(template.exerciseNames.count)", systemImage: "figure.strengthtraining.traditional")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.8))
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
            
            // Exercise list preview
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(template.exerciseNames.prefix(4).enumerated()), id: \.offset) { index, exerciseName in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption.bold())
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text(exerciseName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let goal = goals.first(where: { $0.exerciseName == exerciseName }),
                           goal.targetTime > 0 {
                            Text("< \(goal.targetTime.formatted)")
                                .font(.caption2)
                                .foregroundColor(.yellow.opacity(0.8))
                        }
                        
                        if let exercise = exercises.first(where: { $0.name == exerciseName }) {
                            Image(systemName: iconForCategory(exercise.category))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                if template.exerciseNames.count > 4 {
                    Text("... et \(template.exerciseNames.count - 4) autres")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 100, alignment: .top)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            
            // Start button - reste identique
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
        .shadow(
            color: isActive ? .yellow.opacity(0.3) : .black.opacity(0.2),
            radius: isActive ? 8 : 4,
            y: 2
        )
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
