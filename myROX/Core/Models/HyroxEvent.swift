import Foundation

struct HyroxEvent: Identifiable {
    let id = UUID()
    let imageName: String
    let locationCode: String
    let name: String
    let dateRange: String
    let registrationURL: URL?
} 