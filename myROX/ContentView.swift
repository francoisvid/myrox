import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var navigationService = NotificationNavigationService.shared
    
    var body: some View {
        if authViewModel.isLoggedIn {
            TabView(selection: $navigationService.selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)
                
                WorkoutListView()
                    .tabItem {
                        Label("Entraînements", systemImage: "figure.strengthtraining.traditional")
                    }
                    .tag(1)
                
                StatisticsView()
                    .tabItem {
                        Label("Statistiques", systemImage: "chart.bar")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("Profil", systemImage: "person.circle")
                    }
                    .tag(3)
                
                // 🧪 TEMPORAIRE - Vue de test API
                #if DEBUG
                APITestView()
                    .tabItem {
                        Label("API Test", systemImage: "network")
                    }
                    .tag(4)
                #endif
            }
            .tint(.yellow)
            .sheet(isPresented: $navigationService.shouldShowWorkoutCompletion) {
                // Modale de récapitulatif déclenchée par notification
                if let workout = navigationService.workoutToShow {
                    WorkoutCompletionView(
                        workout: workout,
                        onComplete: {
                            navigationService.resetNavigationState()
                        }
                    )
                }
            }
        } else {
            LoginView()
        }
    }
}
#Preview {
    let mockAuthViewModel = AuthViewModel()
    mockAuthViewModel.isLoggedIn = true // Simuler un utilisateur connecté
    
    return ContentView()
        .environmentObject(mockAuthViewModel)
}
