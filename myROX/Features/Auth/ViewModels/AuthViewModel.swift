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
                let userRepository = UserRepository()
                // S'assurer que l'utilisateur existe
                _ = try await userRepository.syncCurrentUser()
                
                // Vérifier le statut d'onboarding
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
                print("❌ Erreur synchronisation utilisateur: \(error)")
                // En cas d'erreur, on déconnecte
                try? Auth.auth().signOut()
                await MainActor.run {
                    self.isLoggedIn = false
                    self.needsOnboarding = false
                    self.onboardingCompleted = false
                }
            }
        }
    }
    
    private func checkOnboardingCompleted(firebaseUID: String) async throws -> Bool {
        let endpoint = APIEndpoints.userInformations(firebaseUID: firebaseUID)
        
        do {
            let userInfo = try await APIService.shared.get(endpoint, responseType: UserInformationsResponse.self)
            return userInfo.hasCompletedOnboarding
        } catch let error as APIError {
            if case .notFound = error {
                return false // 404 signifie que l'onboarding n'est pas fait
            }
            throw error // Renvoyer les autres erreurs API
        } catch {
            throw error // Renvoyer les erreurs non-API
        }
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
    
    private func handleFirebaseAuth(credential: ASAuthorizationAppleIDCredential) async throws -> FirebaseAuth.User {
        let idTokenString = try credential.getTokenString()
        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: currentNonce ?? ""
        )
        
        let result = try await Auth.auth().signIn(with: firebaseCredential)
        print("✅ Authentification Firebase réussie avec UID: \(result.user.uid)")
        return result.user
    }
    
    private func updateFirebaseProfile(user: FirebaseAuth.User, fullName: PersonNameComponents?) async throws {
        if let givenName = fullName?.givenName,
           let familyName = fullName?.familyName {
            let displayName = "\(givenName) \(familyName)"
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            UserDefaults.standard.set(displayName, forKey: "username")
            print("✅ Profil Firebase mis à jour: \(displayName)")
        }
    }
    
    private func syncUserWithAPI(firebaseUser: FirebaseAuth.User, email: String?) async throws {
        let userRepository = UserRepository()
        do {
            _ = try await userRepository.fetchUserProfile(firebaseUID: firebaseUser.uid)
            print("✅ Utilisateur existant dans l'API")
        } catch {
            print("➕ Création du profil utilisateur dans l'API")
            let newUser = APIUser(
                firebaseUID: firebaseUser.uid,
                email: email ?? firebaseUser.email,
                displayName: UserDefaults.standard.string(forKey: "username")
            )
            _ = try await userRepository.createUserProfile(newUser)
            print("✅ Profil utilisateur créé dans l'API")
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthViewModel: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        // Re-authentification pour suppression de compte
        if Auth.auth().currentUser != nil {
            handleReauthentication(credential: appleIDCredential)
            return
        }
        
        // Connexion normale
        Task {
            do {
                let firebaseUser = try await handleFirebaseAuth(credential: appleIDCredential)
                try await updateFirebaseProfile(user: firebaseUser, fullName: appleIDCredential.fullName)
                
                if let email = appleIDCredential.email {
                    UserDefaults.standard.set(email, forKey: "email")
                }
                
                try await syncUserWithAPI(firebaseUser: firebaseUser, email: appleIDCredential.email)
                
                await MainActor.run {
                    self.isLoggedIn = true
                    self.isLoading = false
                    self.checkOnboardingStatus()
                }
            } catch {
                print("❌ Erreur d'authentification: \(error)")
                try? await Auth.auth().signOut()
                
                await MainActor.run {
                    self.isLoggedIn = false
                    self.isLoading = false
                    self.alertMessage = "Erreur d'authentification: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func handleReauthentication(credential: ASAuthorizationAppleIDCredential) {
        guard let idTokenString = try? credential.getTokenString() else {
            self.alertMessage = "Erreur lors de la récupération du token"
            self.showAlert = true
            return
        }
        
        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: currentNonce ?? ""
        )
        
        Auth.auth().currentUser?.reauthenticate(with: firebaseCredential) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                self.alertMessage = "Erreur de re-authentification: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.performAccountDeletion()
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
                displayName = savedName
            }
        }
        
        // Gérer l'email
        if let email = credential.email {
            UserDefaults.standard.set(email, forKey: "email")
            print("✅ Email Apple: \(email)")
        }
        
        // Créer l'utilisateur dans notre API
        Task {
            do {
                print("🚀 Début de sauvegarde pour l'utilisateur: \(firebaseUser.uid)")
                let userRepository = UserRepository()
                let newUser = APIUser(
                    firebaseUID: firebaseUser.uid,
                    email: credential.email ?? firebaseUser.email,
                    displayName: displayName
                )
                _ = try await userRepository.createUserProfile(newUser)
            } catch {
                print("❌ Erreur création utilisateur API: \(error)")
            }
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

// Extension pour simplifier la récupération du token
extension ASAuthorizationAppleIDCredential {
    func getTokenString() throws -> String {
        guard let appleIDToken = self.identityToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token Apple manquant"])
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir le token"])
        }
        
        return idTokenString
    }
}
