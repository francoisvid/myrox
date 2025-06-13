import SwiftUI
import FirebaseAuth

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var userInformations = UserInformations()
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isCompleted = false
    
    // Étapes d'onboarding
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case hyroxProfile = 1
        case fitnessCondition = 2
        case equipmentGym = 3
        case planning = 4
        case preferences = 5
        case completion = 6
        
        var title: String {
            switch self {
            case .welcome: return "Bienvenue sur myROX!"
            case .hyroxProfile: return "Votre profil HYROX"
            case .fitnessCondition: return "Condition physique"
            case .equipmentGym: return "Équipements & Salle"
            case .planning: return "Planning d'entraînement"
            case .preferences: return "Vos préférences"
            case .completion: return "Félicitations!"
            }
        }
        
        var description: String {
            switch self {
            case .welcome: return "Quelques questions pour personnaliser votre expérience"
            case .hyroxProfile: return "Parlons de votre expérience HYROX"
            case .fitnessCondition: return "Évaluons votre niveau actuel"
            case .equipmentGym: return "Où et comment vous entraînez-vous ?"
            case .planning: return "Organisons votre programme"
            case .preferences: return "Personnalisons vos entraînements"
            case .completion: return "Votre profil est maintenant configuré!"
            }
        }
        
        var progress: Double {
            return Double(self.rawValue) / Double(OnboardingStep.allCases.count - 1)
        }
    }
    
    // Propriétés pour les étapes spécifiques
    @Published var selectedTrainingTypes: Set<TrainingType> = []
    @Published var selectedEquipment: Set<HyroxEquipment> = []
    @Published var selectedDifficultExercises: Set<String> = []
    
    // Validation des étapes
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .hyroxProfile:
            return userInformations.hyroxExperience != nil &&
                   userInformations.hasCompetedHyrox != nil &&
                   userInformations.primaryGoal != nil
        case .fitnessCondition:
            return userInformations.currentTrainingFrequency != nil &&
                   !selectedTrainingTypes.isEmpty &&
                   userInformations.fitnessLevel != nil
        case .equipmentGym:
            return userInformations.familiarWithHyroxStations != nil &&
                   userInformations.hasGymAccess != nil
        case .planning:
            return userInformations.preferredTrainingFrequency != nil &&
                   userInformations.preferredSessionDuration != nil &&
                   userInformations.preferredTrainingTime != nil
        case .preferences:
            return userInformations.preferredIntensity != nil &&
                   userInformations.prefersStructuredProgram != nil &&
                   userInformations.wantsNotifications != nil
        case .completion:
            return true
        }
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        guard canProceed else { return }
        
        // Synchroniser les sélections avec le modèle
        syncSelectionsToModel()
        
        if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? currentStep
            }
        }
    }
    
    func previousStep() {
        if currentStep.rawValue > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? currentStep
            }
        }
    }
    
    func skipToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }
    
    // MARK: - Data Synchronization
    
    private func syncSelectionsToModel() {
        // Synchroniser les types d'entraînement
        userInformations.trainingTypes = Array(selectedTrainingTypes.map { $0.rawValue })
        
        // Synchroniser les équipements
        userInformations.availableEquipment = Array(selectedEquipment.map { $0.rawValue })
        
        // Synchroniser les exercices difficiles
        userInformations.difficultExercises = Array(selectedDifficultExercises)
    }
    
    private func syncModelToSelections() {
        // Synchroniser vers les sets pour l'UI
        selectedTrainingTypes = Set(userInformations.trainingTypes.compactMap { TrainingType(rawValue: $0) })
        selectedEquipment = Set(userInformations.availableEquipment.compactMap { HyroxEquipment(rawValue: $0) })
        selectedDifficultExercises = Set(userInformations.difficultExercises)
    }
    
    // MARK: - API Calls
    
    func completeOnboarding() {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = "Utilisateur non connecté"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Finaliser les données
        syncSelectionsToModel()
        userInformations.hasCompletedOnboarding = true
        
        Task {
            do {
                try await saveUserInformations(firebaseUID: currentUser.uid)
                
                await MainActor.run {
                    self.isLoading = false
                    self.isCompleted = true
                    self.currentStep = .completion
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func saveUserInformations(firebaseUID: String) async throws {
        print("🚀 Début de sauvegarde pour l'utilisateur: \(firebaseUID)")
        
        guard let url = URL(string: "http://localhost:3001/api/v1/users/firebase/\(firebaseUID)/informations") else {
            print("❌ URL invalide")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(firebaseUID, forHTTPHeaderField: "x-firebase-uid")
        
        // Préparer les données pour l'API
        let apiData = OnboardingAPIData(from: userInformations)
        let jsonData = try JSONEncoder().encode(apiData)
        request.httpBody = jsonData
        
        print("📦 Données à envoyer: \(String(data: jsonData, encoding: .utf8) ?? "Impossible d'encoder")")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Réponse invalide")
                throw URLError(.badServerResponse)
            }
            
            print("📡 Status Code: \(httpResponse.statusCode)")
            
            if let responseData = String(data: data, encoding: .utf8) {
                print("📝 Réponse: \(responseData)")
            }
            
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                print("❌ Erreur HTTP: \(httpResponse.statusCode)")
                throw URLError(.badServerResponse)
            }
            
            print("✅ Sauvegarde réussie !")
        } catch {
            print("❌ Erreur lors de la requête: \(error)")
            throw error
        }
    }
    
    func loadUserInformations() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let loadedInfo = try await fetchUserInformations(firebaseUID: currentUser.uid)
            
            await MainActor.run {
                self.userInformations = loadedInfo
                self.syncModelToSelections()
                self.isLoading = false
                
                if loadedInfo.hasCompletedOnboarding {
                    self.isCompleted = true
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                // Si les informations n'existent pas encore, on reste sur l'onboarding
                print("Pas d'informations existantes, début de l'onboarding")
            }
        }
    }
    
    private func fetchUserInformations(firebaseUID: String) async throws -> UserInformations {
        guard let url = URL(string: "http://localhost:3001/api/v1/users/firebase/\(firebaseUID)/informations") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue(firebaseUID, forHTTPHeaderField: "x-firebase-uid")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 404 {
            throw URLError(.fileDoesNotExist) // Pas d'informations existantes
        }
        
        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(UserInformations.self, from: data)
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        currentStep = .welcome
        userInformations = UserInformations()
        selectedTrainingTypes.removeAll()
        selectedEquipment.removeAll()
        selectedDifficultExercises.removeAll()
        isCompleted = false
    }
}

// MARK: - API Data Transfer Object

struct OnboardingAPIData: Codable {
    let hyroxExperience: String?
    let hasCompetedHyrox: Bool?
    let primaryGoal: String?
    let currentTrainingFrequency: String?
    let trainingTypes: [String]
    let fitnessLevel: Int?
    let injuriesLimitations: String?
    let familiarWithHyroxStations: Bool?
    let difficultExercises: [String]
    let hasGymAccess: Bool?
    let gymName: String?
    let gymLocation: String?
    let availableEquipment: [String]
    let preferredTrainingFrequency: String?
    let preferredSessionDuration: String?
    let targetCompetitionDate: String?
    let preferredTrainingTime: String?
    let preferredIntensity: String?
    let prefersStructuredProgram: Bool?
    let wantsNotifications: Bool?
    let hasCompletedOnboarding: Bool
    
    init(from userInfo: UserInformations) {
        self.hyroxExperience = userInfo.hyroxExperience?.rawValue
        self.hasCompetedHyrox = userInfo.hasCompetedHyrox
        self.primaryGoal = userInfo.primaryGoal?.rawValue
        self.currentTrainingFrequency = userInfo.currentTrainingFrequency?.rawValue
        self.trainingTypes = userInfo.trainingTypes
        self.fitnessLevel = userInfo.fitnessLevel
        self.injuriesLimitations = userInfo.injuriesLimitations
        self.familiarWithHyroxStations = userInfo.familiarWithHyroxStations
        self.difficultExercises = userInfo.difficultExercises
        self.hasGymAccess = userInfo.hasGymAccess
        self.gymName = userInfo.gymName
        self.gymLocation = userInfo.gymLocation
        self.availableEquipment = userInfo.availableEquipment
        self.preferredTrainingFrequency = userInfo.preferredTrainingFrequency?.rawValue
        self.preferredSessionDuration = userInfo.preferredSessionDuration?.rawValue
        self.targetCompetitionDate = userInfo.targetCompetitionDate?.ISO8601String()
        self.preferredTrainingTime = userInfo.preferredTrainingTime?.rawValue
        self.preferredIntensity = userInfo.preferredIntensity?.rawValue
        self.prefersStructuredProgram = userInfo.prefersStructuredProgram
        self.wantsNotifications = userInfo.wantsNotifications
        self.hasCompletedOnboarding = userInfo.hasCompletedOnboarding
    }
}

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 