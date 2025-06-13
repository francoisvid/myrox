import SwiftUI

struct OnboardingWelcomeView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                
                // Fonctionnalités principales
                VStack(spacing: 24) {
                    FeatureCard(
                        icon: "target",
                        title: "Programme personnalisé",
                        description: "Adapté à votre niveau et vos objectifs HYROX"
                    )
                    
                    FeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Suivi des progrès",
                        description: "Analysez vos performances et célébrez vos victoires"
                    )
                    
                    FeatureCard(
                        icon: "calendar.badge.clock",
                        title: "Planification intelligente",
                        description: "Séances adaptées à votre emploi du temps"
                    )
                    
                    FeatureCard(
                        icon: "person.crop.circle.badge.checkmark",
                        title: "Coaching expert",
                        description: "Conseils et techniques des meilleurs athlètes HYROX"
                    )
                }
                
                // Message motivationnel
                VStack(spacing: 16) {
                    Text("Prêt à transformer votre potentiel en performance ?")
                        .font(.title3.bold())
                        .foregroundColor(Color.adaptiveTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Répondez à quelques questions pour créer votre profil d'athlète HYROX.")
                        .font(.body)
                        .foregroundColor(Color.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer(minLength: 120) // Espace pour le footer
            }
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextPrimary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.adaptiveBorderColor, lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.adaptiveOnboardingBackground.ignoresSafeArea()
        OnboardingWelcomeView()
            .environmentObject(OnboardingViewModel())
    }
} 
