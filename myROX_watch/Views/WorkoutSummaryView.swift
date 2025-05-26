import SwiftUI

struct WorkoutSummaryView: View {
    let workout: WatchWorkout
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Temps total
                VStack {
                    Text("Temps total")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(workout.totalDuration.formatted)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                // Exercices
                VStack(alignment: .leading, spacing: 10) {
                    Text("Exercices")
                        .font(.headline)
                    
                    ForEach(workout.exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.caption)
                            Spacer()
                            Text(exercise.duration.formatted)
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                // Fréquence cardiaque moyenne
                if let avgHR = calculateAverageHeartRate(workout) {
                    VStack {
                        Text("FC moyenne")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("\(avgHR) bpm")
                                .font(.title3)
                        }
                    }
                }
                
                Button("Terminer") {
                    dismiss()
                }
                .foregroundColor(.green)
            }
            .padding()
        }
        .navigationTitle("Résumé")
        .navigationBarBackButtonHidden(true)
    }
    
    private func calculateAverageHeartRate(_ workout: WatchWorkout) -> Int? {
        let allHeartRates = workout.exercises.flatMap { $0.heartRatePoints.map { $0.value } }
        guard !allHeartRates.isEmpty else { return nil }
        return allHeartRates.reduce(0, +) / allHeartRates.count
    }
}
