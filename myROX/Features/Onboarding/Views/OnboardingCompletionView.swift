import SwiftUI

struct OnboardingCompletionView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var showConfetti = false
    @State private var currentIndex = 0
    @State private var animationTimer: Timer?
    
    let highlights = [
        ("🏃‍♂️", "Profil HYROX"),
        ("💪", "Condition physique"),
        ("🏋️‍♀️", "Équipements & Salle"),
        ("📅", "Planning personnalisé"),
        ("⚙️", "Préférences définies")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // Animation de félicitations
                VStack(spacing: 24) {
                    // Confetti Animation
                    ZStack {
                        if showConfetti {
                            ForEach(0..<40, id: \.self) { index in
                                ConfettiPiece(delay: Double(index) * 0.1)
                            }
                        }
                        
                        // Icône principale
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                            .scaleEffect(showConfetti ? 1.0 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showConfetti)
                    }
                }
                
                // Résumé du profil créé
                VStack(spacing: 20) {
                    HStack {
                        Text("Votre profil en un coup d'œil")
                            .font(.title2.bold())
                            .foregroundColor(Color.adaptiveTextPrimary)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(Array(highlights.enumerated()), id: \.offset) { index, highlight in
                            ProfileHighlightCard(
                                emoji: highlight.0,
                                title: highlight.1,
                                isAnimated: currentIndex >= index
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Prochaines étapes
                VStack(spacing: 16) {
                    HStack {
                        Text("Que se passe-t-il maintenant ?")
                            .font(.title3.bold())
                            .foregroundColor(Color.adaptiveTextPrimary)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        NextStepCard(
                            icon: "figure.run.square.stack",
                            title: "Création de votre programme",
                            description: "Vous ou votre coach pouvez commencer à créer votre programme"
                        )
                        
                        NextStepCard(
                            icon: "calendar.circle",
                            title: "Planification des séances",
                            description: "Organisation selon vos créneaux préférés"
                        )
                        
                        NextStepCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Suivi des progrès",
                            description: "Évolution et statistiques de performance"
                        )
                    }
                }
                
                // Message motivationnel final
                VStack(spacing: 16) {
                    Text("Prêt à révolutionner votre entraînement HYROX ?")
                        .font(.title3.bold())
                        .foregroundColor(Color.adaptiveTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Votre premier workout vous attend dans l'application.")
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
                
                Spacer(minLength: 120) // Espace pour le bouton
            }
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func startAnimations() {
        // Confetti après un délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showConfetti = true
            }
        }
        
        // Animation progressive des highlights
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            if currentIndex < highlights.count {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentIndex += 1
                }
            } else {
                animationTimer?.invalidate()
            }
        }
    }
}

// MARK: - Profile Highlight Card
struct ProfileHighlightCard: View {
    let emoji: String
    let title: String
    let isAnimated: Bool
    
    var body: some View {
        HStack {
            Text(emoji)
                .font(.title)
                .frame(width: 40)
            
            Text(title)
                .font(.headline)
                .foregroundColor(Color.adaptiveTextPrimary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.yellow)
                .opacity(isAnimated ? 1.0 : 0.3)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimated)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isAnimated ? Color.yellow.opacity(0.1) : Color.clear)
                .animation(.easeInOut(duration: 0.3), value: isAnimated)
        )
    }
}

// MARK: - Next Step Card
struct NextStepCard: View {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.adaptiveCardBackground)
        )
    }
}

// MARK: - Confetti Piece
struct ConfettiPiece: View {
    let delay: Double
    @State private var animate = false
    
    let colors: [Color] = [.yellow, .white, .gray, .blue, .green]
    
    var body: some View {
        Rectangle()
            .fill(colors.randomElement() ?? .yellow)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(animate ? 360 : 0))
            .offset(
                x: animate ? CGFloat.random(in: -150...150) : 0,
                y: animate ? CGFloat.random(in: 200...400) : 0
            )
            .opacity(animate ? 0 : 1)
            .animation(
                .easeInOut(duration: 2.0).delay(delay),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

#Preview {
    ZStack {
        Color.adaptiveOnboardingBackground.ignoresSafeArea()
        OnboardingCompletionView()
            .environmentObject(OnboardingViewModel())
            .environmentObject(AuthViewModel())
    }
} 
