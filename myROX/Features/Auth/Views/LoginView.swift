import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo et titre
                VStack(spacing: 24) {
                    Image("logo_myrox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.yellow)
                    
                    Text("MyROX")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Entraînez-vous. Suivez. Progressez.")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Section connexion
                VStack(spacing: 24) {
                    Text("Prêt à vous entraîner ?")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Bouton Sign in with Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            viewModel.signInWithApple()
                        },
                        onCompletion: { result in
                            // Géré dans le ViewModel
                        }
                    )
                    .signInWithAppleButtonStyle(
                        colorScheme == .dark ? .white : .black
                    )
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Mentions légales
                Text("En vous connectant, vous acceptez nos conditions d'utilisation")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            
            // Loading overlay
            if viewModel.isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    .scaleEffect(1.5)
            }
        }
        .alert("Erreur", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}
