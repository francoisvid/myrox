import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        if authViewModel.isLoggedIn {
            TabView(selection: $selectedTab) {
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
            }
            .tint(.yellow)
        } else {
            LoginView()
        }
    }
}
