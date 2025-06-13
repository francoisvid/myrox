import SwiftUI

struct OnboardingPreferencesView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Question 1: Type de séances préférées
                QuestionSection(
                    title: "Quel type de séances préférez-vous ?",
                    description: "Choisissez l'approche qui vous motive le plus"
                ) {
                    VStack(spacing: 12) {
                        ForEach(TrainingIntensity.allCases, id: \.self) { intensity in
                            IntensityCard(
                                intensity: intensity,
                                isSelected: viewModel.userInformations.preferredIntensity == intensity,
                                onTap: {
                                    viewModel.userInformations.preferredIntensity = intensity
                                }
                            )
                        }
                    }
                }
                
                // Question 2: Structure du programme
                QuestionSection(
                    title: "Comment préférez-vous structurer votre entraînement ?",
                    description: "Votre style d'organisation pour les séances"
                ) {
                    VStack(spacing: 12) {
                        ProgramStructureCard(
                            title: "Programme structuré",
                            description: "Plan défini avec séances planifiées à l'avance",
                            icon: "calendar.badge.clock",
                            isSelected: viewModel.userInformations.prefersStructuredProgram == true,
                            onTap: {
                                viewModel.userInformations.prefersStructuredProgram = true
                            }
                        )
                        
                        ProgramStructureCard(
                            title: "Flexibilité totale",
                            description: "Choisir ses séances selon l'envie et le temps disponible",
                            icon: "shuffle",
                            isSelected: viewModel.userInformations.prefersStructuredProgram == false,
                            onTap: {
                                viewModel.userInformations.prefersStructuredProgram = false
                            }
                        )
                    }
                }
                
                // Question 3: Notifications et rappels
                QuestionSection(
                    title: "Souhaitez-vous des rappels pour vos entraînements ?",
                    description: "Notifications pour rester motivé et régulier"
                ) {
                    VStack(spacing: 16) {
                        NotificationCard(
                            title: "Oui, activez les rappels",
                            description: "Notifications personnalisées selon votre planning",
                            icon: "bell.badge",
                            isSelected: viewModel.userInformations.wantsNotifications == true,
                            onTap: {
                                viewModel.userInformations.wantsNotifications = true
                            }
                        )
                        
                        NotificationCard(
                            title: "Non merci",
                            description: "Je préfère m'entraîner sans rappels",
                            icon: "bell.slash",
                            isSelected: viewModel.userInformations.wantsNotifications == false,
                            onTap: {
                                viewModel.userInformations.wantsNotifications = false
                            }
                        )
                        
                        // Info sur les notifications si activées
                        if viewModel.userInformations.wantsNotifications == true {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.yellow)
                                    Text("Types de notifications :")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(Color.adaptiveTextPrimary)
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    NotificationTypeRow(icon: "clock", text: "Rappels d'entraînement")
                                    NotificationTypeRow(icon: "trophy", text: "Félicitations pour vos progrès")
                                    NotificationTypeRow(icon: "target", text: "Rappels d'objectifs")
                                    NotificationTypeRow(icon: "chart.line.uptrend.xyaxis", text: "Résumés de performances")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                
                // Message de motivation finale
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                    
                    VStack(spacing: 8) {
                        Text("Parfait ! Votre profil est prêt")
                            .font(.title2.bold())
                            .foregroundColor(Color.adaptiveTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Nous allons créer un programme d'entraînement HYROX personnalisé selon vos préférences.")
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 16)
                
                Spacer(minLength: 120) // Espace pour le footer
            }
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
    }
}

// MARK: - Intensity Card
struct IntensityCard: View {
    let intensity: TrainingIntensity
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(intensity.displayName)
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary)
                        
                        Text(intensity.description)
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Indicateur de sélection
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .yellow : Color.adaptiveTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.yellow.opacity(0.1) : Color.adaptiveCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.yellow : Color.adaptiveBorderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Program Structure Card
struct ProgramStructureCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(isSelected ? .black.opacity(0.7) : Color.adaptiveTextSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : Color.adaptiveTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.yellow : Color.adaptiveCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.yellow : Color.adaptiveBorderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Card
struct NotificationCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(isSelected ? .black.opacity(0.7) : Color.adaptiveTextSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : Color.adaptiveTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.yellow : Color.adaptiveCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.yellow : Color.adaptiveBorderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Type Row
struct NotificationTypeRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.yellow)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.adaptiveOnboardingBackground.ignoresSafeArea()
        OnboardingPreferencesView()
            .environmentObject(OnboardingViewModel())
    }
} 