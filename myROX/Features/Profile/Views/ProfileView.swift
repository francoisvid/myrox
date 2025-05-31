import SwiftUI
import SwiftData
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingExerciseDefaults = false
    
    init() {
        let context = ModelContainer.shared.mainContext
        _viewModel = StateObject(wrappedValue: ProfileViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header profil
                    ProfileHeaderView(viewModel: viewModel)
                    
                    // Résumé d'activité
                    ActivitySummaryView(viewModel: viewModel)
                    
                    // Objectifs HYROX
                    HyroxGoalsSection()
                    
                    // Paramètres
                    SettingsView(viewModel: viewModel, showingExerciseDefaults: $showingExerciseDefaults)
                    
                    // Déconnexion
                    LogoutButton()
                    
                    // Version
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top)
                }
                .padding()
            }
            .background(Color.adaptiveGradient)
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(viewModel.followSystemTheme ? nil : (viewModel.isDarkModeEnabled ? .dark : .light))
            .onAppear {
                viewModel.refreshUserInfo()
            }
            .sheet(isPresented: $showingExerciseDefaults) {
                ExerciseDefaultsView()
            }
        }
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var isEditing = false
    @State private var draftName = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 80)
                    
                    Text(viewModel.username.prefix(1).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .overlay(
                    Circle()
                        .stroke(Color.yellow, lineWidth: 3)
                )
                
                // Infos
                VStack(alignment: .leading, spacing: 8) {
                    if isEditing {
                        HStack {
                            TextField("Nom", text: $draftName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("OK") {
                                if !draftName.isEmpty {
                                    viewModel.saveUsername(draftName)
                                }
                                isEditing = false
                            }
                            .foregroundColor(.yellow)
                        }
                    } else {
                        HStack {
                            Text(viewModel.username)
                                .font(.title3.bold())
                                .foregroundColor(Color(.label))
                            
                            Button {
                                draftName = viewModel.username
                                isEditing = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Text(viewModel.email)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            // Info si nom par défaut
            if viewModel.username == "Athlète Hyrox" {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("Tapez sur le crayon pour personnaliser votre nom")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Activity Summary

struct ActivitySummaryView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Résumé d'activité")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Entraînements",
                    value: "\(viewModel.totalWorkouts)",
                    icon: "figure.strengthtraining.traditional"
                )
                
                StatCard(
                    title: "Temps total",
                    value: viewModel.totalDuration.shortFormatted,
                    icon: "clock"
                )
                
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f km", viewModel.totalDistance / 1000),
                    icon: "ruler"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var showingExerciseDefaults: Bool
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paramètres")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            // Monitoring cardiaque
            Toggle("Monitoring cardiaque", isOn: $viewModel.isHeartRateMonitoringEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
                .disabled(true) // Pour l'instant
            
            // Unité de poids
            VStack(alignment: .leading) {
                Text("Unité de poids")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Picker("", selection: $viewModel.selectedWeightUnit) {
                    Text("kg").tag(0)
                    Text("lb").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Unité de distance
            VStack(alignment: .leading) {
                Text("Unité de distance")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Picker("", selection: $viewModel.selectedDistanceUnit) {
                    Text("m").tag(0)
                    Text("km").tag(1)
                    Text("mi").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Mode sombre
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mode sombre")
                    
                    Spacer()
                    
                    if viewModel.followSystemTheme {
                        Text("Auto")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("Mode sombre", isOn: $viewModel.isDarkModeEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                    .onChange(of: viewModel.isDarkModeEnabled) { _ in
                        viewModel.toggleDarkMode()
                    }
                
                if !viewModel.followSystemTheme {
                    Button("Suivre le thème système") {
                        viewModel.resetToSystemTheme()
                    }
                    .font(.caption)
                    .foregroundColor(.yellow)
                }
            }
            
            // Valeurs par défaut des exercices
            Button {
                showingExerciseDefaults = true
            } label: {
                Label("Valeurs par défaut des exercices", systemImage: "slider.horizontal.3")
                    .foregroundColor(.yellow)
            }
            
            // Réinitialiser le catalogue d'exercices
            Button {
                showResetAlert = true
            } label: {
                Label("Réinitialiser le catalogue d'exercices", systemImage: "arrow.clockwise")
                    .foregroundColor(.yellow)
            }
            
            // Test des notifications (en mode développement)
            #if DEBUG
            Button {
                Task {
                    let workoutViewModel = WorkoutViewModel(modelContext: ModelContainer.shared.mainContext)
                    workoutViewModel.testNotifications()
                }
            } label: {
                Label("Tester les notifications", systemImage: "bell")
                    .foregroundColor(.orange)
            }
            
            Button {
                Task {
                    let workoutViewModel = WorkoutViewModel(modelContext: ModelContainer.shared.mainContext)
                    workoutViewModel.testWatchNotification()
                }
            } label: {
                Label("Tester notification Apple Watch", systemImage: "applewatch")
                    .foregroundColor(.blue)
            }
            
            Button {
                Task {
                    // Créer un workout de test et déclencher l'ouverture de modale
                    let testWorkout = Workout()
                    testWorkout.templateName = "Test Modal Notification"
                    testWorkout.totalDuration = 1500
                    testWorkout.completedAt = Date()
                    
                    let exercise = WorkoutExercise(exerciseName: "Test Exercise", round: 1, order: 0)
                    exercise.duration = 300
                    exercise.distance = 1000
                    exercise.completedAt = Date()
                    testWorkout.performances.append(exercise)
                    
                    ModelContainer.shared.mainContext.insert(testWorkout)
                    try? ModelContainer.shared.mainContext.save()
                    
                    NotificationNavigationService.shared.testNotificationTap(with: testWorkout)
                }
            } label: {
                Label("Tester ouverture modale", systemImage: "rectangle.on.rectangle")
                    .foregroundColor(.green)
            }
            
            Button {
                Task {
                    // Créer un workout de test et tester le partage directement
                    let testWorkout = Workout()
                    testWorkout.templateName = "Test Partage"
                    testWorkout.totalDuration = 1200
                    testWorkout.completedAt = Date()
                    
                    let exercise = WorkoutExercise(exerciseName: "Test Partage Exercise", round: 1, order: 0)
                    exercise.duration = 240
                    exercise.distance = 500
                    exercise.completedAt = Date()
                    testWorkout.performances.append(exercise)
                    
                    // Tester l'ancien système de partage
                    WorkoutSharingService.shared.shareWorkout(testWorkout)
                }
            } label: {
                Label("Tester partage ancien système", systemImage: "square.and.arrow.up")
                    .foregroundColor(.purple)
            }
            
            Button {
                Task {
                    // Créer un workout de test pour Instagram
                    let testWorkout = Workout()
                    testWorkout.templateName = "Séance HYROX Intense 🔥"
                    testWorkout.totalDuration = 2400 // 40 minutes
                    testWorkout.totalDistance = 3000 // 3km
                    testWorkout.completedAt = Date()
                    
                    let exercise1 = WorkoutExercise(exerciseName: "SkiErg", round: 1, order: 0)
                    exercise1.duration = 180
                    exercise1.distance = 1000
                    exercise1.completedAt = Date()
                    exercise1.isPersonalRecord = true
                    
                    let exercise2 = WorkoutExercise(exerciseName: "Burpees Broad Jump", round: 1, order: 1)
                    exercise2.duration = 300
                    exercise2.repetitions = 80
                    exercise2.completedAt = Date()
                    
                    testWorkout.performances = [exercise1, exercise2]
                    
                    // Tester le partage Instagram
                    WorkoutSharingService.shared.shareToInstagramStories(testWorkout)
                }
            } label: {
                Label("Tester partage Instagram", systemImage: "camera.fill")
                    .foregroundColor(.pink)
            }
            #endif
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Réinitialiser le catalogue", isPresented: $showResetAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Réinitialiser", role: .destructive) {
                Task {
                    try? await ModelContainer.shared.resetExerciseCatalog()
                }
            }
        } message: {
            Text("Cette action va réinitialiser le catalogue d'exercices. Vous devrez redémarrer l'application pour voir les changements.")
        }
    }
}

// MARK: - Logout Button

struct LogoutButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Button {
            authViewModel.signOut()
        } label: {
            Text("Déconnexion")
                .font(.headline)
                .foregroundColor(Color(.label))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
        
        // Dans votre ProfileView ou SettingsView
        Button("Supprimer mon compte") {
            // Afficher une alerte de confirmation d'abord
            showDeleteConfirmation = true
        }
        .foregroundColor(.red)
        .alert("Supprimer le compte", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                authViewModel.deleteAccount()
            }
        } message: {
            Text("Cette action est irréversible. Votre compte et toutes vos données seront définitivement supprimés.")
        }
    }
}

#Preview {
    @State var showingDefaults = false
    
    return ProfileView()
        .environmentObject(AuthViewModel())
        .modelContainer(ModelContainer.shared.container)
}
