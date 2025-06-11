import SwiftUI

struct OnboardingHyroxProfileView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Question 1: Expérience HYROX
                QuestionSection(
                    title: "Quel est votre niveau d'expérience en HYROX ?",
                    description: "Sélectionnez celui qui vous correspond le mieux"
                ) {
                    VStack(spacing: 12) {
                        ForEach(HyroxExperience.allCases, id: \.self) { experience in
                            ExperienceCard(
                                experience: experience,
                                isSelected: viewModel.userInformations.hyroxExperience == experience,
                                onTap: {
                                    viewModel.userInformations.hyroxExperience = experience
                                }
                            )
                        }
                    }
                }
                
                // Question 2: Participation à une compétition
                QuestionSection(
                    title: "Avez-vous déjà participé à une compétition HYROX ?",
                    description: "Même en équipe ou en catégorie découverte"
                ) {
                    HStack(spacing: 16) {
                        YesNoButton(
                            text: "Oui",
                            isSelected: viewModel.userInformations.hasCompetedHyrox == true,
                            onTap: {
                                viewModel.userInformations.hasCompetedHyrox = true
                            }
                        )
                        
                        YesNoButton(
                            text: "Non",
                            isSelected: viewModel.userInformations.hasCompetedHyrox == false,
                            onTap: {
                                viewModel.userInformations.hasCompetedHyrox = false
                            }
                        )
                    }
                }
                
                // Question 3: Objectif principal
                QuestionSection(
                    title: "Quel est votre objectif principal ?",
                    description: "Cela nous aidera à adapter vos entraînements"
                ) {
                    VStack(spacing: 12) {
                        ForEach(HyroxGoal.allCases, id: \.self) { goal in
                            GoalCard(
                                goal: goal,
                                isSelected: viewModel.userInformations.primaryGoal == goal,
                                onTap: {
                                    viewModel.userInformations.primaryGoal = goal
                                }
                            )
                        }
                    }
                }
                
                Spacer(minLength: 120) // Espace pour le footer
            }
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
    }
}

// MARK: - Experience Card
struct ExperienceCard: View {
    let experience: HyroxExperience
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(experience.displayName)
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary)
                        
                        Text(experience.description)
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

// MARK: - Goal Card
struct GoalCard: View {
    let goal: HyroxGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.displayName)
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary)
                        
                        Text(goal.description)
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

// MARK: - Yes/No Button
struct YesNoButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.headline)
                .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(isSelected ? Color.yellow : Color.adaptiveCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(isSelected ? Color.yellow : Color.adaptiveBorderColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Question Section
struct QuestionSection<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.leading)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            content()
        }
    }
}

#Preview {
    ZStack {
        Color.adaptiveOnboardingBackground.ignoresSafeArea()
        OnboardingHyroxProfileView()
            .environmentObject(OnboardingViewModel())
    }
} 
