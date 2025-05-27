import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                Spacer()
                
                // Logo et titre
                VStack(spacing: 24) {
                    Image("logo_myrox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .foregroundColor(.yellow)
                    
                    Text("MyROX")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(.label))
                    
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
                        .foregroundColor(Color(.label))
                    
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
            .background(Color.adaptiveGradient)
            .ignoresSafeArea()
            
            // Loading overlay
            if viewModel.isLoading {
                Color(.label).opacity(0.6)
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
