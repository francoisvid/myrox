import SwiftUI
import SwiftData
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ProfileViewModel
    
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
                    
                    // Objectifs
                    GoalsSection()
                    
                    // Paramètres
                    SettingsView(viewModel: viewModel)
                    
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
            .preferredColorScheme(viewModel.isDarkModeEnabled ? .dark : .light)
            .onAppear {
                viewModel.refreshUserInfo()
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
            Toggle("Mode sombre", isOn: $viewModel.isDarkModeEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
                .onChange(of: viewModel.isDarkModeEnabled) { _ in
                    viewModel.toggleDarkMode()
                }
            
            // Réinitialiser le catalogue d'exercices
            Button {
                showResetAlert = true
            } label: {
                Label("Réinitialiser le catalogue d'exercices", systemImage: "arrow.clockwise")
                    .foregroundColor(.yellow)
            }
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
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .modelContainer(ModelContainer.shared.container)
}
