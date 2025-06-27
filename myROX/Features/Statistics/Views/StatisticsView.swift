import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: StatisticsViewModel
    @State private var showDeleteAllAlert = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    init() {
        let context = ModelContainer.shared.mainContext
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.workouts.isEmpty {
                        emptyStateView
                    } else {
                        // Sélecteur de mode d'affichage
                        viewModeSelector
                        
                        // Sélecteur de période
                        periodSelector
                        
                        // Graphique de progression
                        progressChart
                        
                        // Historique par exercice
                        exerciseHistorySection
                        
                        // Comparaison
                        if viewModel.workouts.count >= 2 {
                            comparisonSection
                        }
                    }
                }
                .padding()
            }
            .background(Color.adaptiveGradient)
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteAllAlert = true
                        } label: {
                            Label("Supprimer tout", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .alert("Supprimer toutes les séances", isPresented: $showDeleteAllAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    Task {
                        await deleteAllWorkouts()
                    }
                }
            } message: {
                Text("Cette action supprimera définitivement toutes vos séances.")
            }
            .alert("Erreur", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .refreshable {
                await viewModel.forceFullSync()
            }
            .overlay {
                if isDeleting {
                    ProgressView("Suppression en cours...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteAllWorkouts() async {
        isDeleting = true
        
        do {
            try await viewModel.deleteAllWorkouts()
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        isDeleting = false
    }
    
    private func deleteWorkout(_ workout: Workout) async {
        isDeleting = true
        
        do {
            try await viewModel.deleteWorkout(workout)
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        isDeleting = false
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucune donnée")
                .font(.title2.bold())
                .foregroundColor(Color(.label))
            
            Text("Terminez des entraînements pour voir vos statistiques")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    private var viewModeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mode d'affichage")
                .font(.subheadline.bold())
                .foregroundColor(Color(.label))
            
            HStack(spacing: 8) {
                ForEach(StatisticsViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.selectedViewMode = mode
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(isSelected(mode) ? .primary : .secondary)
                            
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(isSelected(mode) ? .primary.opacity(0.8) : .secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected(mode) ? Color.accentColor.opacity(0.15) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected(mode) ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color(.separator), lineWidth: 0.5)
//        )
    }

    private func isSelected(_ mode: StatisticsViewMode) -> Bool {
        viewModel.selectedViewMode == mode
    }
    
    private var periodSelector: some View {
        HStack {
            ForEach(["3 mois", "6 mois", "1 an", "2 ans"].indices, id: \.self) { index in
                Button {
                    viewModel.selectedPeriodIndex = index
                } label: {
                    Text(["3 mois", "6 mois", "1 an", "2 ans"][index])
                        .font(.subheadline)
                        .foregroundColor(viewModel.selectedPeriodIndex == index ? .black : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedPeriodIndex == index ? Color.yellow : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progression des temps")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            if viewModel.chartData.isEmpty {
                Text("Pas encore de données")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                Chart(viewModel.chartData, id: \.0) { item in
                    AreaMark(
                        x: .value("Date", item.0),
                        y: .value("Temps", item.1)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.yellow.opacity(0.3), .yellow.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Date", item.0),
                        y: .value("Temps", item.1)
                    )
                    .foregroundStyle(Color.yellow)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", item.0),
                        y: .value("Temps", item.1)
                    )
                    .foregroundStyle(Color.yellow)
                    .annotation(position: .top) {
                        Text(item.1.formatted)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .chartYScale(domain: 0...(viewModel.chartData.map { $0.1 }.max() ?? 0) * 1.2)
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel {
                            if let time = value.as(TimeInterval.self) {
                                Text(time.formatted)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: viewModel.chartData.map { $0.0 }) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.day().month(.abbreviated))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var exerciseHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Historique par exercice")
                    .font(.title3.bold())
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                if viewModel.selectedViewMode == .detailed {
                    Label("Variantes séparées", systemImage: "list.bullet.indent")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Label("Vue groupée", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            ForEach(viewModel.uniqueExerciseKeys, id: \.self) { exerciseKey in
                EnhancedExerciseHistoryCard(
                    exerciseKey: exerciseKey,
                    history: viewModel.exerciseHistory(for: exerciseKey),
                    personalBest: viewModel.personalBest(for: exerciseKey),
                    viewMode: viewModel.selectedViewMode,
                    onDelete: { exercise in
                        if let workout = viewModel.workouts.first(where: {
                            $0.performances.contains(where: { $0.id == exercise.id })
                        }) {
                            Task {
                                await deleteWorkout(workout)
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparaison")
                .font(.title3.bold())
                .foregroundColor(Color(.label))
            
            let (previous, latest) = viewModel.comparison()
            
            if let prev = previous, let lat = latest {
                ComparisonCard(previous: prev, latest: lat)
            }
        }
    }
}

// MARK: - Enhanced Exercise History Card

struct EnhancedExerciseHistoryCard: View {
    let exerciseKey: String
    let history: [(WorkoutExercise, Date)]
    let personalBest: WorkoutExercise?
    let viewMode: StatisticsViewMode
    let onDelete: (WorkoutExercise) -> Void
    
    @State private var showDeleteAlert = false
    @State private var exerciseToDelete: WorkoutExercise?
    
    private var displayName: String {
        if let firstExercise = history.first?.0 {
            return viewMode == .detailed ? firstExercise.displayName : firstExercise.exerciseName
        }
        return exerciseKey
    }
    
    private var exerciseParameters: (distance: Double?, repetitions: Int?) {
        guard let firstExercise = history.first?.0 else { return (nil, nil) }
        return (
            firstExercise.distance > 0 ? firstExercise.distance : nil,
            firstExercise.repetitions > 0 ? firstExercise.repetitions : nil
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with exercise info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                    
                    if viewMode == .detailed {
                        HStack(spacing: 8) {
                            if let distance = exerciseParameters.distance {
                                Label("\(Int(distance))m", systemImage: "ruler")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            if let reps = exerciseParameters.repetitions {
                                Label("\(reps) reps", systemImage: "repeat")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            if exerciseParameters.distance == nil && exerciseParameters.repetitions == nil {
                                Label("Temps seulement", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if let best = personalBest {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("Record", systemImage: "trophy.fill")
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                        Text(best.duration.formatted)
                            .font(.subheadline.bold())
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            
            // Statistics summary
            if history.count > 1 {
                HStack(spacing: 16) {
                    StatsSummaryItem(
                        title: "Séances",
                        value: "\(history.count)",
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    
                    if let avgTime = averageTime {
                        StatsSummaryItem(
                            title: "Temps moyen",
                            value: avgTime.formatted,
                            icon: "clock.fill",
                            color: .green
                        )
                    }
                    
                    if let improvement = improvement {
                        StatsSummaryItem(
                            title: improvement.isImprovement ? "Amélioration" : "Dégradation",
                            value: improvement.value.formatted,
                            icon: improvement.isImprovement ? "arrow.down" : "arrow.up",
                            color: improvement.isImprovement ? .green : .red
                        )
                    }
                    
                    Spacer()
                }
            }
            
            // History list
            List {
                ForEach(history.prefix(3), id: \.0.id) { exercise, date in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(date, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(date, format: .dateTime.hour().minute())
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            if exercise.distance > 0 {
                                Text("\(Int(exercise.distance))m")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            if exercise.repetitions > 0 {
                                Text("\(exercise.repetitions) reps")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text(exercise.duration.formatted)
                                .font(.subheadline.bold())
                                .foregroundColor(exercise.id == personalBest?.id ? .yellow : Color(.label))
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(history.count > 1 ? .visible : .hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            exerciseToDelete = exercise
                            showDeleteAlert = true
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: CGFloat(history.prefix(3).count * 44))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Supprimer la séance", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                if let exercise = exerciseToDelete {
                    onDelete(exercise)
                }
            }
        } message: {
            Text("La suppression de cet exercice supprimera toute la séance associée.")
        }
    }
    
    private var averageTime: TimeInterval? {
        guard !history.isEmpty else { return nil }
        let total = history.reduce(0) { $0 + $1.0.duration }
        return total / Double(history.count)
    }
    
    private var improvement: (value: TimeInterval, isImprovement: Bool)? {
        guard history.count >= 2 else { return nil }
        let latest = history[0].0.duration
        let previous = history[1].0.duration
        let diff = latest - previous
        return (abs(diff), diff < 0)
    }
}

// MARK: - Stats Summary Item

struct StatsSummaryItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption.bold())
                    .foregroundColor(Color(.label))
            }
        }
    }
}

// MARK: - Comparison Card

struct ComparisonCard: View {
    let previous: Workout
    let latest: Workout
    
    private var improvement: TimeInterval {
        latest.totalDuration - previous.totalDuration
    }
    
    private var isImproved: Bool {
        improvement < 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Latest workout
            HStack {
                VStack(alignment: .leading) {
                    Text("Dernière séance")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let date = latest.completedAt {
                        Text(date, format: .dateTime.day().month())
                            .font(.caption)
                            .foregroundColor(Color(.label))
                    }
                }
                
                Spacer()
                
                Text(latest.totalDuration.formatted)
                    .font(.headline)
                    .foregroundColor(Color(.label))
            }
            
            Divider()
            
            // Previous workout
            HStack {
                VStack(alignment: .leading) {
                    Text("Séance précédente")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let date = previous.completedAt {
                        Text(date, format: .dateTime.day().month())
                            .font(.caption)
                            .foregroundColor(Color(.label))
                    }
                }
                
                Spacer()
                
                Text(previous.totalDuration.formatted)
                    .font(.headline)
                    .foregroundColor(Color(.label))
            }
            
            // Difference
            HStack {
                Text("Différence")
                    .font(.subheadline)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: isImproved ? "arrow.down" : "arrow.up")
                    Text(abs(improvement).formatted)
                }
                .font(.headline)
                .foregroundColor(isImproved ? .green : .red)
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(ModelContainer.shared.container)
}
