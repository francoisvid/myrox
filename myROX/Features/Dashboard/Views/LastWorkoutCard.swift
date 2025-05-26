//import SwiftUI
//
//struct LastWorkoutCard: View {
//    let workout: Workout
//    @State private var showDetails = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // Header avec durée
//            HStack {
//                VStack(alignment: .leading) {
//                    Text("Temps total")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                    Text(workout.totalDuration.formatted)
//                        .font(.largeTitle.bold())
//                        .foregroundColor(.yellow)
//                }
//                
//                Spacer()
//                
//                if let date = workout.completedAt {
//                    VStack(alignment: .trailing) {
//                        Text(date.relativeFormatted)
//                            .font(.caption.bold())
//                            .foregroundColor(.white)
//                        Text(date.timeFormatted)
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                }
//            }
//            
//            // Toggle pour les détails
//            Button {
//                withAnimation(.easeInOut(duration: 0.2)) {
//                    showDetails.toggle()
//                }
//            } label: {
//                HStack {
//                    Text(showDetails ? "Masquer les détails" : "Voir les détails")
//                        .font(.caption)
//                        .foregroundColor(.yellow)
//                    
//                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
//                        .font(.caption)
//                        .foregroundColor(.yellow)
//                }
//            }
//            
//            // Détails des exercices
//            if showDetails {
//                Divider()
//                    .background(Color.gray.opacity(0.3))
//                
//                ForEach(workout.performances) { exercise in
//                    HStack {
//                        Text(exercise.exerciseName)
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                        
//                        Spacer()
//                        
//                        Text(exercise.duration.formatted)
//                            .font(.caption.bold())
//                            .foregroundColor(.white)
//                    }
//                    .padding(.vertical, 2)
//                }
//            }
//        }
//        .padding()
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//    }
//}
