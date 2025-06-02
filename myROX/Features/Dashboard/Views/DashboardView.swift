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
            .onAppear {
                // Forcer le rechargement des stats si nécessaire
                if statsViewModel.personalBests.isEmpty && !statsViewModel.workouts.isEmpty {
                    statsViewModel.loadWorkouts()
                }
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
                
                // Exercices dans l'ordre chronologique
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercices")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Trier les exercices par ordre chronologique (round + order)
                    let sortedExercises = workout.performances.sorted { first, second in
                        if first.round != second.round {
                            return first.round < second.round
                        }
                        return first.order < second.order
                    }
                    
                    // Afficher chaque exercice individuellement
                    ForEach(sortedExercises, id: \.id) { exercise in
                        IndividualExerciseView(
                            exercise: exercise,
                            personalBest: getBestForExercise(exercise, from: statsViewModel),
                            isNewRecord: isNewRecord(exercise, personalBest: getBestForExercise(exercise, from: statsViewModel)),
                            allWorkoutExercises: workout.performances
                        )
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
    
    // MARK: - Helper Functions
    
    private func getBestForExercise(_ exercise: WorkoutExercise, from statsViewModel: StatisticsViewModel) -> WorkoutExercise? {
        let key = exercise.statisticsKey
        return statsViewModel.personalBests[key]
    }
    
    private func isNewRecord(_ exercise: WorkoutExercise, personalBest: WorkoutExercise?) -> Bool {
        guard let best = personalBest else { return false }
        return exercise.duration < best.duration && exercise.duration > 0
    }
    
    // Fonction pour déterminer si on doit afficher les rounds
    private func shouldShowRounds(_ exercises: [WorkoutExercise]) -> Bool {
        // Afficher les rounds seulement si :
        // 1. Il y a plusieurs exercices de la même séquence (vraiment consécutifs)
        // 2. OU s'il y a des rounds différents dans la séquence
        if exercises.count > 1 {
            return true
        }
        
        // Pour un seul exercice, vérifier s'il y a d'autres exercices du même type dans le workout global
        guard let firstExercise = exercises.first else { return false }
        
        // Si c'est un exercice unique dans toute la séance, pas besoin d'afficher le round
        return false
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

// MARK: - Individual Exercise View

struct IndividualExerciseView: View {
    let exercise: WorkoutExercise
    let personalBest: WorkoutExercise?
    let isNewRecord: Bool
    let allWorkoutExercises: [WorkoutExercise]
    
    private var displayParameters: String {
        var params: [String] = []
        if exercise.distance > 0 {
            params.append("\(Int(exercise.distance))m")
        }
        if exercise.repetitions > 0 {
            params.append("\(exercise.repetitions) reps")
        }
        
        return params.isEmpty ? "" : " • " + params.joined(separator: " • ")
    }
    
    // Détermine si on doit afficher le round
    private var shouldShowRound: Bool {
        // Compter le nombre de rounds uniques dans tout le workout
        let uniqueRounds = Set(allWorkoutExercises.map { $0.round })
        
        // Afficher le round seulement s'il y a plus d'un round différent
        return uniqueRounds.count > 1
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Colonne principale (nom + status)
            VStack(alignment: .leading, spacing: 2) {
                // Nom de l'exercice avec paramètres et icône record
                HStack(spacing: 4) {
                    if isNewRecord {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Text(exercise.exerciseName)
                        .font(.subheadline.bold())
                        .foregroundColor(Color(.label))
                    
                    Text(displayParameters)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Status (Round ou Réalisé)
                if shouldShowRound {
                    Text("Round \(exercise.round)")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("Réalisé")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Colonne temps (alignée à droite)
            VStack(alignment: .trailing, spacing: 2) {
                Text(exercise.duration.formatted)
                    .font(.subheadline.bold())
                    .foregroundColor(exercise.duration == personalBest?.duration ? .yellow : Color(.label))
                
                // Record personnel en dessous
                if let best = personalBest {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text(best.duration.formatted)
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

#Preview {
    DashboardView()
        .modelContainer(ModelContainer.shared.container)
}
