import SwiftUI
import SwiftData
import FirebaseAuth

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username = UserDefaults.standard.string(forKey: "username") ?? "Athlète Hyrox"
    @Published var email = UserDefaults.standard.string(forKey: "email") ?? "user@example.com"
    @Published var totalWorkouts: Int = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var totalDistance: Double = 0
    
    @AppStorage("isHeartRateMonitoringEnabled") var isHeartRateMonitoringEnabled = true
    @AppStorage("selectedWeightUnit") var selectedWeightUnit = 0
    @AppStorage("selectedDistanceUnit") var selectedDistanceUnit = 0
    @AppStorage("isDarkModeEnabled") var isDarkModeEnabled: Bool = {
        // Par défaut, suivre le thème système
        UITraitCollection.current.userInterfaceStyle == .dark
    }()
    @AppStorage("followSystemTheme") var followSystemTheme = true
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Initialiser le thème selon le système si c'est la première fois
        if followSystemTheme {
            isDarkModeEnabled = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        loadUserInfo()
        loadStatistics()
        
        // Observer les changements d'authentification
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.loadUserInfo()
        }
    }
    
    // MARK: - User Info Management
    
    private func loadUserInfo() {
        guard let user = Auth.auth().currentUser else {
            username = UserDefaults.standard.string(forKey: "username") ?? "Athlète Hyrox"
            email = UserDefaults.standard.string(forKey: "email") ?? "user@example.com"
            return
        }
        
        if let displayName = user.displayName, !displayName.isEmpty {
            username = displayName
        } else {
            username = UserDefaults.standard.string(forKey: "username") ?? "Athlète Hyrox"
        }
        
        if let userEmail = user.email, !userEmail.isEmpty {
            email = userEmail
        } else {
            email = UserDefaults.standard.string(forKey: "email") ?? "Email masqué"
        }
        
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(email, forKey: "email")
    }
    
    func refreshUserInfo() {
        loadUserInfo()
        loadStatistics()
    }
    
    private func loadStatistics() {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.completedAt != nil }
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            totalWorkouts = workouts.count
            totalDuration = workouts.reduce(0) { $0 + $1.totalDuration }
            totalDistance = workouts.reduce(0) { $0 + $1.totalDistance }
        } catch {
            print("Erreur chargement statistiques: \(error)")
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        time.formatted
    }
    
    func saveUsername(_ newName: String) {
        username = newName
        UserDefaults.standard.set(newName, forKey: "username")
        
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = newName
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Erreur mise à jour profil Firebase: \(error.localizedDescription)")
                } else {
                    print("Profil Firebase mis à jour")
                }
            }
        }
    }
    
    func toggleDarkMode() {
        isDarkModeEnabled.toggle()
        followSystemTheme = false // L'utilisateur a pris le contrôle manuel
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkModeEnabled ? .dark : .light
            }
        }
    }
    
    func resetToSystemTheme() {
        followSystemTheme = true
        isDarkModeEnabled = UITraitCollection.current.userInterfaceStyle == .dark
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .unspecified // Suivre le système
            }
        }
    }
}
