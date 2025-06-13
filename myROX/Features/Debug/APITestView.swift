import SwiftUI
import FirebaseAuth

struct APITestView: View {
    @State private var healthResponse: HealthResponse?
    @State private var userResponse: APIUser?
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Test Health Check
                    Section {
                        Button("Test Health Check") {
                            testHealthCheck()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if let health = healthResponse {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("✅ API Response:")
                                    .font(.headline)
                                Text("Status: \(health.status)")
                                Text("Version: \(health.version)")
                                Text("Environment: \(health.environment)")
                                Text("Message: \(health.message)")
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Divider()
                    
                    // Test User Profile
                    Section {
                        Button("Test User Profile") {
                            testUserProfile()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(Auth.auth().currentUser == nil)
                        
                        if Auth.auth().currentUser == nil {
                            Text("⚠️ Vous devez être connecté pour tester le profil")
                                .foregroundColor(.orange)
                        }
                        
                        if let user = userResponse {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("✅ User Response:")
                                    .font(.headline)
                                Text("ID: \(user.id)")
                                Text("Firebase UID: \(user.firebaseUID)")
                                Text("Email: \(user.email ?? "N/A")")
                                Text("Display Name: \(user.displayName ?? "N/A")")
                                Text("Coach ID: \(user.coachId ?? "None")")
                                Text("Created: \(user.createdAt)")
                                Text("UUID: \(user.uuid)")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if !errorMessage.isEmpty {
                        Text("❌ Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if isLoading {
                        ProgressView("Testing API...")
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("API Test")
        }
    }
    
    private func testHealthCheck() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let response = try await APIService.shared.healthCheck()
                await MainActor.run {
                    healthResponse = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func testUserProfile() {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let response = try await APIService.shared.get(
                    .userProfile(firebaseUID: firebaseUser.uid),
                    responseType: APIUser.self
                )
                await MainActor.run {
                    userResponse = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    APITestView()
} 