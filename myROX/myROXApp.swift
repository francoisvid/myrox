import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MyROXApp: App {
    let modelContainer = ModelContainer.shared
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isInitialized = false
    @State private var isFirstLaunch = true
    
    init() {
        // Configurer Firebase
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
                } else if authViewModel.isLoggedIn {
                    ContentView()
                        .environmentObject(authViewModel)
                        .background(Color.adaptiveGradient)
                } else if isFirstLaunch {
                    SplashScreenView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                isFirstLaunch = false
                            }
                        }
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .modelContainer(modelContainer.container)
        }
    }
    
    private func initializeApp() async {
        do {
            try await modelContainer.initializeExerciseCatalog()
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
