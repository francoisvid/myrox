import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MyROXApp: App {
    let modelContainer = ModelContainer.shared
    @StateObject private var authViewModel = AuthViewModel()
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
            try await modelContainer.initializeExerciseCatalog()
            
            // Nettoyer automatiquement les anciens templates au démarrage
            await MainActor.run {
                let workoutViewModel = WorkoutViewModel(modelContext: modelContainer.mainContext)
                workoutViewModel.cleanupLegacyTemplates()
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
