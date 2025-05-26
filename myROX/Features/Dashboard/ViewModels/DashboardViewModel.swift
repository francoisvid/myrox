import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var lastWorkout: Workout?
    @Published var upcomingEvents: [HyroxEvent] = []
    @Published var isLoading = false
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
        setupEvents()
    }
    
    func loadData() {
        loadLastWorkout()
    }
    
    private func loadLastWorkout() {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.completedAt != nil },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            lastWorkout = try modelContext.fetch(descriptor).first
        } catch {
            print("Erreur chargement dernier workout: \(error)")
        }
    }
    
    private func setupEvents() {
        // Events fictifs pour l'instant
        upcomingEvents = [
            HyroxEvent(
                imageName: "hyrox_prs",
                locationCode: "PAR",
                name: "FITNESS PARK HYROX PARIS",
                dateRange: "23. Oct. 2025 – 26. Oct. 2025",
                registrationURL: URL(string: "https://hyroxfrance.com/fr/trouve-ta-course/?filter_region=france")
            ),
            HyroxEvent(
                imageName: "hyrox_bdx",
                locationCode: "BDX",
                name: "HYROX BORDEAUX",
                dateRange: "20. Nov. 2025 – 23. Nov. 2025",
                registrationURL: URL(string: "https://hyroxfrance.com/fr/trouve-ta-course/?filter_region=france")
            )
        ]
    }
}

// MARK: - Event Model
struct HyroxEvent: Identifiable {
    let id = UUID()
    let imageName: String
    let locationCode: String
    let name: String
    let dateRange: String
    let registrationURL: URL?
}
