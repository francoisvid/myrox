import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MyROXApp: App {
    let modelContainer = ModelContainer.shared
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var exerciseSyncService = ExerciseSyncService.shared
    @State private var isInitialized = false
    @State private var showSplash = true
    @State private var splashStartTime: Date?
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !isInitialized {
                    ProgressView("Initialisation...")
                        .task {
                            await initializeApp()
                        }
                } else if showSplash {
                    SplashScreenView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            if splashStartTime == nil {
                                splashStartTime = Date()
                                
                                // Délai minimum de 3 secondes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        showSplash = false
                                    }
                                }
                            }
                        }
                } else if authViewModel.isLoggedIn {
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(exerciseSyncService)
                        .background(Color.adaptiveGradient)
                        .transition(.opacity)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                }
            }
            .modelContainer(modelContainer.container)
        }
    }
    
    private func initializeApp() async {
        do {
            // RESET TEMPORAIRE : Nettoyer les anciens exercices avec distances
            // À supprimer après la première utilisation
            try await modelContainer.resetExerciseCatalog()
            
            // Initialiser les exercices locaux d'abord (maintenant vide)
            try await modelContainer.initializeExerciseCatalog()
            
            // Puis synchroniser avec l'API si possible
            await exerciseSyncService.syncExercisesIfNeeded(modelContext: modelContainer.mainContext)
            
            // 🚀 NOUVEAU : Synchroniser les workouts non synchronisés au démarrage
            let workoutRepository = WorkoutRepository(modelContext: modelContainer.mainContext)
            await WorkoutSyncService.shared.syncUnsyncedWorkouts(with: workoutRepository)
            
            // Nettoyer automatiquement les anciens templates au démarrage
            await MainActor.run {
                let workoutViewModel = WorkoutViewModel(modelContext: modelContainer.mainContext)
                workoutViewModel.cleanupLegacyTemplates()
            }
            
            // Demander les permissions de notification
            let notificationGranted = await NotificationService.shared.requestPermission()
            if notificationGranted {
                print("Permissions de notification accordées")
            } else {
                print("Permissions de notification refusées")
            }
            
            await MainActor.run {
                isInitialized = true
            }
        } catch {
            print("Erreur lors de l'initialisation: \(error)")
            await MainActor.run {
                isInitialized = true
            }
        }
    }
}

extension Color {
    static let adaptiveBackground: Color = {
        Color(.systemBackground)
    }()
    
    static let adaptiveGradient: LinearGradient = {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.secondarySystemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }()
}
