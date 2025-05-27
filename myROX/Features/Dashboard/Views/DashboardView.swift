import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var statsViewModel: StatisticsViewModel
    
    init() {
        let context = ModelContainer.shared.mainContext
        _viewModel = StateObject(wrappedValue: DashboardViewModel(modelContext: context))
        _statsViewModel = StateObject(wrappedValue: StatisticsViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Dernier entraînement
                    lastWorkoutSection
                    
                    // Événements à venir
                    upcomingEventsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Sections
    
    private var lastWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dernier entraînement")
                .font(.title3.bold())
                .foregroundColor(Color(.label))
            
            if let workout = viewModel.lastWorkout {
                LastWorkoutCard(workout: workout, statsViewModel: statsViewModel)
            } else {
                NoWorkoutCard()
            }
        }
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prochains événements HYROX")
                .font(.title3.bold())
                .foregroundColor(Color(.label))
            
            ForEach(viewModel.upcomingEvents) { event in
                EventCard(event: event)
            }
        }
    }
}

// MARK: - Last Workout Card

struct LastWorkoutCard: View {
    let workout: Workout
    let statsViewModel: StatisticsViewModel
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Durée totale
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Durée totale")
                        .font(.caption)
                        .foregroundColor(.gray)
                        
                    Text(workout.totalDuration.formatted)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                // Date
                if let date = workout.completedAt {
                    VStack(alignment: .trailing) {
                        Text(date, format: .dateTime.day().month())
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(date, format: .dateTime.hour().minute())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Toggle pour les détails
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
            
            if showDetails {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Exercices
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercices")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Grouper les exercices par nom
                    let groupedExercises = Dictionary(grouping: workout.performances) { $0.exerciseName }
                    
                    ForEach(groupedExercises.keys.sorted(), id: \.self) { exerciseName in
                        if let exercises = groupedExercises[exerciseName] {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if let personalBest = statsViewModel.personalBests[exerciseName],
                                       exercises.contains(where: { $0.duration < personalBest.duration }) {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    Text(exerciseName)
                                        .font(.subheadline)
                                        .foregroundColor(Color(.label))
                                    
                                    Spacer()
                                    
                                    // Afficher le meilleur temps de l'exercice
                                    if let personalBest = statsViewModel.personalBests[exerciseName] {
                                        Text(personalBest.duration.formatted)
                                            .font(.subheadline)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                
                                // Afficher les performances par round
                                ForEach(exercises.sorted(by: { $0.round < $1.round }), id: \.id) { exercise in
                                    HStack {
                                        Text("Round \(exercise.round)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            if exercise.distance > 0 {
                                                Text("\(Int(exercise.distance))m")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            if exercise.repetitions > 0 {
                                                Text("\(exercise.repetitions)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Text(exercise.duration.formatted)
                                                .font(.subheadline.bold())
                                                .foregroundColor(Color(.label))
                                        }
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            // Distance totale si disponible
            if workout.totalDistance > 0 {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack {
                    Text("Distance totale")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f km", workout.totalDistance / 1000))
                        .font(.subheadline.bold())
                        .foregroundColor(Color(.label))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - No Workout Card

struct NoWorkoutCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Aucun entraînement")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            Text("Commencez votre premier workout pour voir vos statistiques")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK - Compare performances

struct PerformanceComparisonRow: View {
    let exerciseName: String
    let currentPerformance: WorkoutExercise
    let personalBest: WorkoutExercise
    
    private var improvement: TimeInterval {
        currentPerformance.duration - personalBest.duration
    }
    
    private var isNewRecord: Bool {
        currentPerformance.duration < personalBest.duration && currentPerformance.duration > 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(exerciseName)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                if isNewRecord {
                    Label("Nouveau record!", systemImage: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Actuel")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(currentPerformance.duration.formatted)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                VStack {
                    Text("Record")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(personalBest.duration.formatted)
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Diff")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 2) {
                        Image(systemName: improvement < 0 ? "arrow.down" : "arrow.up")
                            .font(.caption)
                        Text(abs(improvement).formatted)
                            .font(.headline)
                    }
                    .foregroundColor(improvement < 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
        .modelContainer(ModelContainer.shared.container)
}
