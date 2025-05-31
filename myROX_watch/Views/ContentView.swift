import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataService: WatchDataService
    
    var body: some View {
        NavigationStack {
            List {
                // Statistiques
                Section {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.yellow)
                        Text("Workouts complétés")
                        Spacer()
                        Text("\(dataService.workoutCount)")
                            .foregroundColor(.yellow)
                            .bold()
                    }
                }
                
                // Templates
                Section {
                    HStack {
                        Text("Templates")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text("\(dataService.templates.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                    
                    if dataService.templates.isEmpty {
                        Text("Aucun template")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(dataService.templates) { template in
                            NavigationLink(destination: WorkoutDetailView(template: template)) {
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text("\(template.templateExercises.count) exercices")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                // Workout actif
                if dataService.activeWorkout != nil {
                    Section {
                        NavigationLink(destination: ActiveWorkoutView()) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.green)
                                Text("Workout en cours")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("MyROX")
            .onAppear {
                dataService.requestTemplates()
                dataService.requestWorkoutCount()
                dataService.requestGoals()
            }
        }
    }
}

struct WorkoutDetailView: View {
    let template: WatchTemplate
    @EnvironmentObject var dataService: WatchDataService
    @State private var navigateToActiveWorkout = false
    
    var body: some View {
        List {
            Section("Exercices") {
                ForEach(template.templateExercises, id: \.id) { templateExercise in
                    WatchExerciseRow(templateExercise: templateExercise)
                }
            }
            
            Button {
                dataService.startWorkoutSession(for: template)
                navigateToActiveWorkout = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                    Text("DÉMARRER")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(template.name)
        .navigationDestination(isPresented: $navigateToActiveWorkout) {
            ActiveWorkoutView()
        }
    }
}

// MARK: - Watch Exercise Row
struct WatchExerciseRow: View {
    let templateExercise: WatchTemplateExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(templateExercise.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            WatchExerciseParametersView(templateExercise: templateExercise)
        }
    }
}

// MARK: - Watch Exercise Parameters View
struct WatchExerciseParametersView: View {
    let templateExercise: WatchTemplateExercise
    
    var body: some View {
        HStack(spacing: 6) {
            if let distance = templateExercise.targetDistance, distance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "ruler")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("\(Int(distance))m")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
            }
            
            if let reps = templateExercise.targetRepetitions, reps > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "repeat")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("\(reps)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
            }
            
            if templateExercise.targetDistance == nil && templateExercise.targetRepetitions == nil {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("temps")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
            }
        }
    }
}
