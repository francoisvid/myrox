import SwiftUI

struct WorkoutCompletionView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingShareSheet = false
    var onComplete: (() -> Void)? = nil // Callback optionnel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Célébration
                    VStack(spacing: 13) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Séance terminée !")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Félicitations pour cette excellente séance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 10)
                    
                    // Carte des statistiques
                    let totalPerformances = workout.performances.filter { $0.completedAt != nil }.count
                    let shouldUseCompactMode = totalPerformances > 4
                    WorkoutShareCard(workout: workout, isCompact: shouldUseCompactMode)
                    
                    // Boutons d'action
                    VStack(spacing: 12) {
                        // Boutons de partage
                        HStack(spacing: 12) {
                            // Partage Instagram
                            Button(action: {
                                let totalPerformances = workout.performances.filter { $0.completedAt != nil }.count
                                let useCompactMode = totalPerformances > 4
                                WorkoutSharingService.shared.shareToInstagramStories(workout, showAllExercises: useCompactMode, colorScheme: colorScheme)
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Instagram")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            
                            // Partage général
                            ShareLink(
                                item: WorkoutSharingService.shared.generateShareText(for: workout),
                                subject: Text("Ma séance myROX"),
                                message: Text("Regarde ma séance d'entraînement !")
                            ) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Partager")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            onComplete?()
                            dismiss()
                        }) {
                            Text("Continuer")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, 16) // Padding externe pour toute la VStack
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        onComplete?()
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled() // Empêcher la fermeture par swipe
    }
}
//
//#Preview {
//    // Créer un conteneur de test en mémoire
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: Workout.self, WorkoutExercise.self, configurations: config)
//    let context = container.mainContext
//    
//    // Créer un workout de test
//    let workout = Workout()
//    workout.templateName = "Séance test"
//    workout.totalDuration = 1800 // 30 minutes
//    workout.totalDistance = 2000 // 2km
//    workout.completedAt = Date()
//    
//    // Ajouter quelques exercices de test
//    let exercise1 = WorkoutExercise(exerciseName: "Exercice 1", round: 1, order: 0)
//    exercise1.duration = 30
//    exercise1.completedAt = Date()
//    exercise1.isPersonalRecord = true
//    
//    let exercise2 = WorkoutExercise(exerciseName: "Exercice 2", round: 1, order: 1)
//    exercise2.duration = 35
//    exercise2.completedAt = Date()
//    
//    workout.performances = [exercise1, exercise2]
//    
//    // Insérer dans le contexte
//    context.insert(workout)
//    context.insert(exercise1)
//    context.insert(exercise2)
//    
//    return WorkoutCompletionView(workout: workout)
//        .modelContainer(container)
//} 
