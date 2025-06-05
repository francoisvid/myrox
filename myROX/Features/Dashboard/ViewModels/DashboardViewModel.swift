import Foundation
import SwiftData
import FirebaseAuth

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var lastWorkout: Workout?
    @Published var templates: [WorkoutTemplate] = []
    @Published var userProfile: APIUser?
    @Published var coachInfo: Coach?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var upcomingEvents: [HyroxEvent] = []
    
    private let modelContext: ModelContext
    private let userRepository: UserRepositoryProtocol
    private let templateRepository: TemplateRepositoryProtocol
    
    init(
        modelContext: ModelContext,
        userRepository: UserRepositoryProtocol = UserRepository(),
        templateRepository: TemplateRepositoryProtocol? = nil
    ) {
        self.modelContext = modelContext
        self.userRepository = userRepository
        self.templateRepository = templateRepository ?? TemplateRepository(modelContext: modelContext)
        
        loadData()
        loadUpcomingEvents()
    }
    
    // MARK: - Public Methods
    
    func loadData() {
        Task {
            await loadUserProfile()
            await syncWithAPI()
            loadLocalData()
        }
    }
    
    func refreshData() {
        Task {
            isLoading = true
            await syncWithAPI()
            loadLocalData()
            isLoading = false
        }
    }
    
    // MARK: - API Synchronization
    
    private func loadUserProfile() async {
        do {
            userProfile = try await userRepository.syncCurrentUser()
            
            // Load coach info if user has a coach
            if let coachUUID = userProfile?.coachUUID {
                coachInfo = try await userRepository.fetchCoach(coachId: coachUUID)
            }
        } catch {
            handleError("Erreur lors du chargement du profil", error)
        }
    }
    
    private func syncWithAPI() async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            // Sync templates with API
            try await templateRepository.syncTemplatesWithCache()
            print("✅ Templates synchronisés avec l'API")
        } catch {
            handleError("Erreur de synchronisation API", error)
            // Continue with local data even if API sync fails
        }
    }
    
    // MARK: - Local Data Loading
    
    private func loadLocalData() {
        loadLastWorkout()
        loadTemplates()
    }
    
    private func loadLastWorkout() {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            lastWorkout = workouts.first
        } catch {
            handleError("Erreur lors du chargement des entraînements", error)
        }
    }
    
    private func loadTemplates() {
        templates = templateRepository.getCachedTemplates()
    }
    
    // MARK: - HYROX Events
    
    private func loadUpcomingEvents() {
        // Mock data for HYROX events - replace with real API call
        upcomingEvents = [
            HyroxEvent(
                imageName: "hyrox_prs",
                locationCode: "PAR",
                name: "HYROX Paris",
                dateRange: "23. Oct. 2025 – 26. Oct. 2025",
                registrationURL: URL(string: "https://hyroxfrance.com/fr/trouve-ta-course/?filter_region=france")
            ),
            HyroxEvent(
                imageName: "hyrox_bdx",
                locationCode: "BDX",
                name: "HYROX Bordeaux",
                dateRange: "20. Nov. 2025 – 23. Nov. 2025",
                registrationURL: URL(string: "https://hyroxfrance.com/fr/trouve-ta-course/?filter_region=france")
            )
        ]
    }
    
    // MARK: - Template Management
    
    func createTemplate(name: String, rounds: Int = 1) async {
        do {
            isLoading = true
            
            let request = CreateTemplateRequest(
                name: name,
                rounds: rounds,
                exercises: []
            )
            
            _ = try await templateRepository.createTemplate(request)
            
            // Refresh local cache
            try await templateRepository.syncTemplatesWithCache()
            loadTemplates()
            
        } catch {
            handleError("Erreur lors de la création du template", error)
        }
        
        isLoading = false
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) async {
        do {
            isLoading = true
            
            // Convert UUID to String for API
            let templateId = template.id.uuidString
            try await templateRepository.deleteTemplate(id: templateId)
            
            // Remove from local cache
            modelContext.delete(template)
            try modelContext.save()
            
            // Refresh templates list
            loadTemplates()
            
        } catch {
            handleError("Erreur lors de la suppression du template", error)
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    var isCoached: Bool {
        return userProfile?.coachUUID != nil
    }
    
    var personalTemplatesCount: Int {
        return templates.filter { isPersonalTemplate($0) }.count
    }
    
    var assignedTemplatesCount: Int {
        return templates.filter { !isPersonalTemplate($0) }.count
    }
    
    // MARK: - Helper Methods
    
    private func isPersonalTemplate(_ template: WorkoutTemplate) -> Bool {
        // For now, assume all cached templates are personal
        // This logic will need to be enhanced when we add template ownership info
        return true
    }
    
    private func handleError(_ message: String, _ error: Error) {
        print("❌ \(message): \(error)")
        errorMessage = message
        
        // Clear error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.errorMessage = nil
        }
    }
}


