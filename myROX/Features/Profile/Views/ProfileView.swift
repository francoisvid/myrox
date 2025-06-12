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
                    
                    // Gestion du coach
                    CoachManagementView()
                    
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
    @State private var userProfile: APIUser?
    
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
                        
                        // Informations supplémentaires
                        HStack(spacing: 16) {
                            // Date de création
                            if let profile = userProfile {
                                Text("Membre depuis \(formatDateFrench(profile.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
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
        .onAppear {
            loadUserProfile()
        }
    }
    
    private func loadUserProfile() {
        Task {
            do {
                let userRepository = UserRepository()
                userProfile = try await userRepository.syncCurrentUser()
            } catch {
                print("Erreur chargement profil: \(error)")
            }
        }
    }
    
    private func formatDateFrench(_ dateString: String) -> String {
        // L'API retourne probablement une date ISO8601, on va la parser et la reformater
        let isoFormatter = ISO8601DateFormatter()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        if let date = isoFormatter.date(from: dateString) {
            return dateFormatter.string(from: date)
        }
        
        // Fallback si le parsing échoue
        return dateString
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
    @EnvironmentObject var exerciseSyncService: ExerciseSyncService
    @Environment(\.modelContext) private var modelContext
    @State private var showAuditResults = false
    @State private var auditResults: (onlyLocal: [String], onlyAPI: [String], common: [String]) = ([], [], [])
    @State private var showCleanupConfirmation = false
    @State private var cleanupResults: (deleted: Int, kept: Int) = (0, 0)
    @State private var showCleanupResults = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paramètres")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            // Synchronisation des exercices
            exerciseSyncSection
            
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
            
            // Thème d'apparence
            VStack(alignment: .leading, spacing: 8) {
                Text("Thème")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Picker("Thème", selection: Binding(
                    get: { viewModel.themeSelection },
                    set: { viewModel.themeSelection = $0 }
                )) {
                    Text("Auto").tag(0)
                    Text("Clair").tag(1)
                    Text("Sombre").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
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
        .alert("Nettoyer les exercices", isPresented: $showCleanupConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Nettoyer", role: .destructive) {
                Task {
                    cleanupResults = await exerciseSyncService.cleanupLocalExercises(modelContext: modelContext)
                    showCleanupResults = true
                }
            }
        } message: {
            Text("Cette action va supprimer définitivement tous les exercices locaux qui ne sont plus présents dans l'API. Cette opération est irréversible.")
        }
        .alert("Résultats du nettoyage", isPresented: $showCleanupResults) {
            Button("OK") { }
        } message: {
            Text("Nettoyage terminé :\n• \(cleanupResults.deleted) exercices supprimés\n• \(cleanupResults.kept) exercices conservés")
        }
        .sheet(isPresented: $showAuditResults) {
            ExerciseAuditResultsView(results: auditResults)
        }
    }
    
    private var exerciseSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                Text("Synchronisation exercices")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                if exerciseSyncService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Statut de synchronisation
            VStack(alignment: .leading, spacing: 6) {
                if let lastSync = exerciseSyncService.lastSyncDate {
                    HStack {
                        Text("Dernière sync:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(lastSync, style: .relative)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("Aucune synchronisation effectuée")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if exerciseSyncService.newExercisesCount > 0 {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(exerciseSyncService.newExercisesCount) nouveaux exercices")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if let error = exerciseSyncService.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Erreur: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }
                }
            }
            
            // Bouton de synchronisation manuelle
            Button {
                Task {
                    await exerciseSyncService.forceSync(modelContext: modelContext)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Synchroniser maintenant")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .disabled(exerciseSyncService.isLoading)
            
            // Boutons d'audit et nettoyage
            HStack(spacing: 12) {
                // Bouton d'audit
                Button {
                    Task {
                        auditResults = await exerciseSyncService.auditLocalExercises(modelContext: modelContext)
                        showAuditResults = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Audit")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
                .disabled(exerciseSyncService.isLoading)
                
                // Bouton de nettoyage
                Button {
                    showCleanupConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Nettoyer")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .disabled(exerciseSyncService.isLoading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

// MARK: - Exercise Audit Results View

struct ExerciseAuditResultsView: View {
    let results: (onlyLocal: [String], onlyAPI: [String], common: [String])
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Résumé
                    summarySection
                    
                    // Exercices seulement locaux (problématiques)
                    if !results.onlyLocal.isEmpty {
                        exerciseSection(
                            title: "⚠️ Seulement en local",
                            subtitle: "Ces exercices seront supprimés lors du prochain nettoyage",
                            exercises: results.onlyLocal,
                            color: .red
                        )
                    }
                    
                    // Exercices seulement dans l'API
                    if !results.onlyAPI.isEmpty {
                        exerciseSection(
                            title: "📥 Seulement dans l'API",
                            subtitle: "Ces exercices seront ajoutés lors de la prochaine synchronisation",
                            exercises: results.onlyAPI,
                            color: .blue
                        )
                    }
                    
                    // Exercices communs (ok)
                    exerciseSection(
                        title: "✅ Exercices synchronisés",
                        subtitle: "Ces exercices sont présents localement et dans l'API",
                        exercises: results.common,
                        color: .green,
                        collapsed: true
                    )
                }
                .padding()
            }
            .navigationTitle("Audit des exercices")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Résumé de l'audit")
                .font(.headline)
                .foregroundColor(Color(.label))
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Local uniquement",
                    value: "\(results.onlyLocal.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                StatCard(
                    title: "API uniquement", 
                    value: "\(results.onlyAPI.count)",
                    icon: "cloud.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Synchronisés",
                    value: "\(results.common.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func exerciseSection(
        title: String,
        subtitle: String,
        exercises: [String],
        color: Color,
        collapsed: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if !collapsed || exercises.count <= 5 {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(exercises, id: \.self) { exercise in
                        HStack {
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                            
                            Text(exercise)
                                .font(.caption)
                                .foregroundColor(Color(.label))
                            
                            Spacer()
                        }
                    }
                }
            } else {
                Text("+ \(exercises.count) exercices (tap pour développer)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Stat Card for Audit

extension StatCard {
    init(title: String, value: String, icon: String, color: Color) {
        self.init(title: title, value: value, icon: icon)
        // Note: Il faudrait modifier StatCard pour supporter la couleur custom
    }
}

// MARK: - Coach Management

struct CoachManagementView: View {
    @State private var userProfile: APIUser?
    @State private var coachInfo: APICoach?
    @State private var isLoading = false
    @State private var showingInvitationInput = false
    @State private var invitationCode = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header avec titre et icône check
            HStack {
                Text("Mon Coach")
                    .font(.headline)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                if coachInfo != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        Text("Lié")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            if let coach = coachInfo {
                // Affichage du coach actuel
                coachInfoSection(coach: coach)
            } else {
                // Interface pour se lier à un coach
                invitationSection
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            loadUserProfile()
        }
        .sheet(isPresented: $showingInvitationInput) {
            InvitationCodeInputView(
                onCodeSubmitted: { code in
                    submitInvitationCode(code)
                },
                onCancel: {
                    showingInvitationInput = false
                }
            )
        }
    }
    
    private func coachInfoSection(coach: APICoach) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar coach
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(coachInitial(from: coach.displayName))
                            .font(.title2.bold())
                            .foregroundColor(.blue)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(coach.displayName)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                    
                    if let specialization = coach.specialization {
                        Text("Spécialité: \(specialization)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    if let bio = coach.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                    }
                }
                
                Spacer()
            }
            
            // Certifications
            if let certifications = coach.certifications, !certifications.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Certifications")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)
                    ], alignment: .leading, spacing: 6) {
                        ForEach(certifications, id: \.self) { certification in
                            Text(certification)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Statistiques du coach
            HStack(spacing: 20) {
                StatItem(title: "Athlètes", value: "\(coach.athleteCount ?? 0)")
                StatItem(title: "Workouts", value: "\(coach.totalWorkouts ?? 0)")
                if let avgDuration = coach.averageWorkoutDuration, avgDuration > 0 {
                    StatItem(title: "Durée moy.", value: "\(avgDuration / 60)min")
                }
            }
        }
    }
    
    private var invitationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aucun coach assigné")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(.label))
                    
                    Text("Demandez un code d'invitation à votre coach pour vous lier à lui")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Messages d'erreur/succès
            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            if !successMessage.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Bouton pour saisir le code
            Button {
                showingInvitationInput = true
                errorMessage = ""
                successMessage = ""
            } label: {
                HStack {
                    Image(systemName: "ticket")
                    Text("Saisir un code d'invitation")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
    }
    
    private func loadUserProfile() {
        Task {
            do {
                let userRepository = UserRepository()
                userProfile = try await userRepository.syncCurrentUser()
                
                // Charger les infos du coach si disponible
                if let coachUUID = userProfile?.coachUUID {
                    coachInfo = try await userRepository.fetchCoach(coachId: coachUUID)
                }
            } catch {
                print("Erreur chargement profil: \(error)")
            }
        }
    }
    
    private func submitInvitationCode(_ code: String) {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = ""
                successMessage = ""
                showingInvitationInput = false
            }
            
            do {
                let result = try await AuthRepository().useInvitationCode(code: code)
                
                await MainActor.run {
                    successMessage = result.message
                    isLoading = false
                    
                    // Recharger le profil pour afficher le nouveau coach
                    loadUserProfile()
                }
            } catch {
                await MainActor.run {
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .badRequest(let message):
                            errorMessage = message ?? "Requête invalide"
                        case .notFound:
                            errorMessage = "Code d'invitation invalide"
                        case .forbidden(let message):
                            errorMessage = message ?? "Accès interdit"
                        default:
                            errorMessage = "Erreur lors de la liaison avec le coach"
                        }
                    } else {
                        errorMessage = "Erreur de connexion"
                    }
                    isLoading = false
                }
            }
        }
    }
    
    private func coachInitial(from name: String?) -> String {
        guard let name = name, let firstChar = name.first else {
            return "C"
        }
        return String(firstChar).uppercased()
    }
}

// MARK: - Invitation Code Input View

struct InvitationCodeInputView: View {
    @State private var code = ""
    @State private var isValidCode = false
    let onCodeSubmitted: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Code d'invitation")
                        .font(.title.bold())
                        .foregroundColor(Color(.label))
                    
                    Text("Saisissez le code à 6 caractères fourni par votre coach")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Input du code
                VStack(spacing: 16) {
                    TextField("Code d'invitation", text: $code)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2.monospaced())
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .textContentType(.oneTimeCode)
                        .keyboardType(.asciiCapable)
                        .onChange(of: code) { newValue in
                            // Limiter à 6 caractères et convertir en majuscules
                            let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                            if filtered.count <= 6 {
                                code = filtered
                                isValidCode = filtered.count == 6
                            } else {
                                code = String(filtered.prefix(6))
                                isValidCode = true
                            }
                        }
                    
                    // Indicateur visuel de validation
                    HStack {
                        ForEach(0..<6, id: \.self) { index in
                            Circle()
                                .fill(index < code.count ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                
                // Bouton de validation
                Button {
                    onCodeSubmitted(code)
                } label: {
                    Text("Valider le code")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidCode ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValidCode)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Liaison Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        onCancel()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Stat Item Helper

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(Color(.label))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    @State var showingDefaults = false
    
    return ProfileView()
        .environmentObject(AuthViewModel())
        .modelContainer(ModelContainer.shared.container)
}
