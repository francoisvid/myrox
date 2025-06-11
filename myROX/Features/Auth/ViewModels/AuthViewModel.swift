import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
class AuthViewModel: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isLoggedIn = false
    @Published var needsOnboarding = false
    @Published var onboardingCompleted = false
    
    // Propriété pour stocker le nonce sécurisé
    private var currentNonce: String?
    
    override init() {
        super.init()
        // Vérifier si l'utilisateur est déjà connecté
        checkAuthenticationState()
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() {
        isLoading = true
        
        // Générer un nonce sécurisé
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce) // Hasher le nonce pour Apple
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - Authentication State
    private func checkAuthenticationState() {
        // Vérifier si un utilisateur est déjà connecté
        if Auth.auth().currentUser != nil {
            isLoggedIn = true
            checkOnboardingStatus()
        }
    }
    
    // Vérifier le statut d'onboarding
    private func checkOnboardingStatus() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        Task {
            do {
                let hasCompleted = try await checkOnboardingCompleted(firebaseUID: currentUser.uid)
                
                await MainActor.run {
                    if hasCompleted {
                        self.onboardingCompleted = true
                        self.needsOnboarding = false
                    } else {
                        self.needsOnboarding = true
                        self.onboardingCompleted = false
                    }
                }
            } catch {
                // Si erreur (pas d'informations), on suppose qu'il faut faire l'onboarding
                await MainActor.run {
                    self.needsOnboarding = true
                    self.onboardingCompleted = false
                }
            }
        }
    }
    
    private func checkOnboardingCompleted(firebaseUID: String) async throws -> Bool {
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
            return false // Pas d'informations = onboarding requis
        }
        
        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            throw URLError(.badServerResponse)
        }
        
        let userInfo = try JSONDecoder().decode(UserInformationsResponse.self, from: data)
        return userInfo.hasCompletedOnboarding
    }
    
    // Marquer l'onboarding comme complété
    func markOnboardingCompleted() {
        onboardingCompleted = true
        needsOnboarding = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            
            // Nettoyer les données locales
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.removeObject(forKey: "email")
        } catch let signOutError as NSError {
            alertMessage = "Erreur lors de la déconnexion: \(signOutError.localizedDescription)"
            showAlert = true
        }
    }
    
    // MARK: - Nonce Generation
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Account Deletion
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "Aucun utilisateur connecté."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Pour Apple Sign In, il faut parfois re-authentifier avant de supprimer
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            deleteAppleAccount()
        } else {
            performAccountDeletion()
        }
    }

    private func deleteAppleAccount() {
        // Re-authentification Apple requise pour la suppression
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = []
        
        // Générer un nouveau nonce pour la re-auth
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    private func performAccountDeletion() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        user.delete { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    // Si l'erreur indique qu'une re-auth est nécessaire
                    if (error as NSError).code == AuthErrorCode.requiresRecentLogin.rawValue {
                        self.alertMessage = "Pour supprimer votre compte, veuillez vous reconnecter puis réessayer."
                    } else {
                        self.alertMessage = "Erreur lors de la suppression du compte: \(error.localizedDescription)"
                    }
                    self.showAlert = true
                } else {
                    // Suppression réussie
                    print("✅ Compte supprimé avec succès")
                    self.cleanupAfterDeletion()
                }
            }
        }
    }

    private func cleanupAfterDeletion() {
        // Nettoyer toutes les données locales
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "email")
        
        // Remettre à zéro l'état d'authentification
        isLoggedIn = false
        
        // Optionnel : Afficher un message de confirmation
        alertMessage = "Votre compte a été supprimé avec succès."
        showAlert = true
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthViewModel: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isLoading = false
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                self.alertMessage = "Impossible d'obtenir le token d'identité Apple."
                self.showAlert = true
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                self.alertMessage = "Impossible de convertir le token d'identité en chaîne."
                self.showAlert = true
                return
            }
            
            let firebaseCredential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: currentNonce ?? ""
            )
            
            // Vérifier si c'est une re-auth pour suppression ou une connexion normale
            if Auth.auth().currentUser != nil {
                // Re-authentification pour suppression
                Auth.auth().currentUser?.reauthenticate(with: firebaseCredential) { [weak self] _, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.alertMessage = "Erreur de re-authentification: \(error.localizedDescription)"
                        self.showAlert = true
                    } else {
                        // Re-auth réussie, procéder à la suppression
                        self.performAccountDeletion()
                    }
                }
            } else {
                // Connexion normale
                Auth.auth().signIn(with: firebaseCredential) { [weak self] (authResult, error) in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.alertMessage = "Erreur d'authentification Firebase avec Apple: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    if let authResult = authResult {
                        print("Connexion Firebase avec Apple réussie ! User: \(authResult.user.uid)")
                        self.isLoggedIn = true
                        self.handleAppleUserInfo(credential: appleIDCredential, firebaseUser: authResult.user)
                        self.checkOnboardingStatus()
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        
        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .canceled:
                print("Connexion avec Apple annulée par l'utilisateur.")
            case .failed:
                self.alertMessage = "Échec de l'autorisation Apple."
                self.showAlert = true
            case .invalidResponse:
                self.alertMessage = "Réponse invalide d'Apple."
                self.showAlert = true
            case .notHandled:
                self.alertMessage = "Demande non gérée par Apple."
                self.showAlert = true
            case .notInteractive:
                self.alertMessage = "Connexion impossible en mode non-interactif."
                self.showAlert = true
            case .unknown:
                self.alertMessage = "Erreur inconnue lors de l'autorisation Apple."
                self.showAlert = true
            @unknown default:
                self.alertMessage = "Erreur d'autorisation Apple: \(authorizationError.localizedDescription)"
                self.showAlert = true
            }
        } else {
            self.alertMessage = "Erreur inconnue lors de la connexion avec Apple: \(error.localizedDescription)"
            self.showAlert = true
        }
    }
    
    // MARK: - Handle Apple User Info
    private func handleAppleUserInfo(credential: ASAuthorizationAppleIDCredential, firebaseUser: FirebaseAuth.User) {
        var displayName: String?
        
        // Vérifier si on a le nom complet (première connexion)
        if let fullName = credential.fullName,
           let givenName = fullName.givenName,
           let familyName = fullName.familyName {
            
            displayName = "\(givenName) \(familyName)"
            print("✅ Première connexion Apple - Nom récupéré: \(displayName!)")
            
            // Sauvegarder immédiatement
            UserDefaults.standard.set(displayName, forKey: "username")
            
            // Mettre à jour Firebase
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Erreur mise à jour profil: \(error.localizedDescription)")
                } else {
                    print("✅ Profil Firebase mis à jour")
                }
            }
        } else {
            print("⚠️ Connexion Apple suivante - Pas de nom fourni")
            // Vérifier si on a déjà un nom sauvegardé
            if let savedName = UserDefaults.standard.string(forKey: "username"),
               savedName != "Athlète Hyrox" {
                print("✅ Nom existant trouvé: \(savedName)")
            }
        }
        
        // Gérer l'email
        if let email = credential.email {
            UserDefaults.standard.set(email, forKey: "email")
            print("✅ Email Apple: \(email)")
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// MARK: - Response Models
struct UserInformationsResponse: Codable {
    let hasCompletedOnboarding: Bool
}
