import SwiftUI

struct OnboardingCoordinatorView: View {
   @StateObject private var viewModel = OnboardingViewModel()
   @EnvironmentObject private var authViewModel: AuthViewModel
   @Environment(\.dismiss) private var dismiss
   
   var body: some View {
       NavigationView {
           ZStack {
               // Gradient de fond adaptatif
               Color.adaptiveOnboardingBackground
                   .ignoresSafeArea()
               
               VStack(spacing: 0) {
                   // Header avec progression
                   OnboardingHeaderView(
                       currentStep: viewModel.currentStep,
                       progress: viewModel.currentStep.progress
                   )
                   
                   // Contenu principal
                   TabView(selection: $viewModel.currentStep) {
                       OnboardingWelcomeView()
                           .tag(OnboardingViewModel.OnboardingStep.welcome)
                       
                       OnboardingHyroxProfileView()
                           .tag(OnboardingViewModel.OnboardingStep.hyroxProfile)
                       
                       OnboardingFitnessConditionView()
                           .tag(OnboardingViewModel.OnboardingStep.fitnessCondition)
                       
                       OnboardingEquipmentGymView()
                           .tag(OnboardingViewModel.OnboardingStep.equipmentGym)
                       
                       OnboardingPlanningView()
                           .tag(OnboardingViewModel.OnboardingStep.planning)
                       
                       OnboardingPreferencesView()
                           .tag(OnboardingViewModel.OnboardingStep.preferences)
                       
                       OnboardingCompletionView()
                           .tag(OnboardingViewModel.OnboardingStep.completion)
                   }
                   .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                   .environmentObject(viewModel)
                   
                   // Footer avec boutons de navigation
                   OnboardingFooterView(
                       currentStep: viewModel.currentStep,
                       canProceed: viewModel.canProceed,
                       isLoading: viewModel.isLoading,
                       onPrevious: viewModel.previousStep,
                       onNext: {
                           if viewModel.currentStep == .preferences {
                               viewModel.completeOnboarding()
                           } else {
                               viewModel.nextStep()
                           }
                       },
                       onSkip: {
                           viewModel.skipToStep(.completion)
                       },
                       onComplete: {
                           authViewModel.markOnboardingCompleted()
                       }
                   )
               }
           }
           .navigationBarHidden(true)
       }
       .navigationViewStyle(StackNavigationViewStyle())
       .onAppear {
           Task {
               await viewModel.loadUserInformations()
           }
       }
       .alert("Erreur", isPresented: $viewModel.showAlert) {
           Button("OK", role: .cancel) { }
       } message: {
           Text(viewModel.alertMessage)
       }
   }
}

// MARK: - Header View
struct OnboardingHeaderView: View {
   let currentStep: OnboardingViewModel.OnboardingStep
   let progress: Double
   
   var body: some View {
       VStack(spacing: 16) {
           // Logo et titre principal
           HStack {
               HStack(spacing: 8) {
                   // Logo ou icône de substitution
                   if let _ = UIImage(named: "logo_myrox") {
                       Image("logo_myrox")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 40, height: 40)
                           .foregroundColor(.yellow)
                           .cornerRadius(20)
                   } else {
                       // Fallback si l'image n'existe pas
                       Image(systemName: "figure.strengthtraining.traditional")
                           .font(.title)
                           .foregroundColor(.yellow)
                           .frame(width: 40, height: 40)
                   }
                   
                   Text("MyROX")
                       .font(.title2.bold())
                       .foregroundColor(Color.adaptiveTextPrimary)
               }
               
               Spacer()
               
               // Indicateur d'étape
               Text("\(currentStep.rawValue + 1)/\(OnboardingViewModel.OnboardingStep.allCases.count)")
                   .font(.caption)
                   .foregroundColor(Color.adaptiveTextSecondary)
                   .padding(.horizontal, 12)
                   .padding(.vertical, 4)
                   .background(Color.adaptiveCardBackground)
                   .cornerRadius(12)
           }
           .padding(.horizontal, 24)
           .padding(.top, 16)
           
           // Barre de progression
           ProgressView(value: progress)
               .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
               .scaleEffect(y: 2)
               .clipShape(Capsule())
               .padding(.horizontal, 24)
           
           // Titre et description de l'étape
           VStack(spacing: 8) {
               Text(currentStep.title)
                   .font(.title2.bold())
                   .foregroundColor(Color.adaptiveTextPrimary)
                   .multilineTextAlignment(.center)
               
               Text(currentStep.description)
                   .font(.body)
                   .foregroundColor(Color.adaptiveTextSecondary)
                   .multilineTextAlignment(.center)
           }
           .padding(.horizontal, 24)
       }
       .padding(.bottom, 20)
   }
}

// MARK: - Footer View
struct OnboardingFooterView: View {
   let currentStep: OnboardingViewModel.OnboardingStep
   let canProceed: Bool
   let isLoading: Bool
   let onPrevious: () -> Void
   let onNext: () -> Void
   let onSkip: () -> Void
   let onComplete: () -> Void
   
   var body: some View {
       VStack(spacing: 16) {
           // Boutons de navigation
           if currentStep != .completion {
               HStack(spacing: 16) {
                   // Bouton Précédent
                   if currentStep.rawValue > 0 {
                       Button(action: onPrevious) {
                           HStack(spacing: 8) {
                               Image(systemName: "chevron.left")
                               Text("Précédent")
                           }
                           .font(.system(size: 16, weight: .medium))
                           .foregroundColor(Color.adaptiveTextPrimary)
                           .padding(.horizontal, 20)
                           .padding(.vertical, 12)
                           .background(Color.adaptiveCardBackground)
                           .cornerRadius(25)
                       }
                       .disabled(isLoading)
                   }
                   
                   Spacer()
                   Spacer()
                   
                   // Bouton Suivant/Terminer
                   Button(action: onNext) {
                       HStack(spacing: 8) {
                           if isLoading {
                               ProgressView()
                                   .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                   .scaleEffect(0.8)
                           } else {
                               Text(currentStep == .preferences ? "Terminer" : "Suivant")
                               Image(systemName: "chevron.right")
                           }
                       }
                       .font(.system(size: 16, weight: .medium))
                       .foregroundColor(.black)
                       .padding(.horizontal, 24)
                       .padding(.vertical, 12)
                       .background(canProceed ? Color.yellow : Color.gray.opacity(0.5))
                       .cornerRadius(25)
                   }
                   .disabled(!canProceed || isLoading)
               }
               .padding(.horizontal, 24)
           } else {
               // Bouton "Commencer l'aventure" centré
               Button(action: onComplete) {
                   HStack(spacing: 8) {
                       Text("Commencer l'aventure")
                       Image(systemName: "arrow.right.circle.fill")
                   }
                   .font(.system(size: 18, weight: .bold))
                   .foregroundColor(.black)
                   .padding(.horizontal, 32)
                   .padding(.vertical, 16)
                   .background(Color.yellow)
                   .cornerRadius(30)
                   .shadow(color: Color.yellow.opacity(0.3), radius: 10, x: 0, y: 5)
               }
               .padding(.horizontal, 24)
           }
           
           // Texte d'aide
           if !canProceed && currentStep != .welcome && currentStep != .completion {
               Text("Veuillez répondre à toutes les questions pour continuer")
                   .font(.caption)
                   .foregroundColor(.orange)
                   .multilineTextAlignment(.center)
                   .padding(.horizontal, 24)
           }
       }
       .padding(.vertical, 20)
       .background(
           LinearGradient(
               gradient: Gradient(colors: [
                   Color.clear,
                   Color(.systemBackground).opacity(0.3)
               ]),
               startPoint: .top,
               endPoint: .bottom
           )
       )
   }
}

#Preview {
   OnboardingCoordinatorView()
       .environmentObject(AuthViewModel())
}
