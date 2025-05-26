import SwiftUI

@main
struct MyROXWatchApp: App {
    @StateObject private var dataService = WatchDataService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
        }
    }
}
