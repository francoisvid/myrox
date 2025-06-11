import SwiftUI

struct OnboardingFitnessConditionView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var injuriesText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Question 1: Fréquence d'entraînement actuelle
                QuestionSection(
                    title: "À quelle fréquence vous entraînez-vous actuellement ?",
                    description: "Toutes activités sportives confondues"
                ) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(TrainingFrequency.allCases, id: \.self) { frequency in
                            FrequencyCard(
                                frequency: frequency,
                                isSelected: viewModel.userInformations.currentTrainingFrequency == frequency,
                                onTap: {
                                    viewModel.userInformations.currentTrainingFrequency = frequency
                                }
                            )
                        }
                    }
                }
                
                // Question 2: Types d'entraînement
                QuestionSection(
                    title: "Quels types d'entraînement pratiquez-vous ?",
                    description: "Sélectionnez toutes vos activités (plusieurs choix possibles)"
                ) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(TrainingType.allCases, id: \.self) { type in
                            TrainingTypeCard(
                                type: type,
                                isSelected: viewModel.selectedTrainingTypes.contains(type),
                                onTap: {
                                    if viewModel.selectedTrainingTypes.contains(type) {
                                        viewModel.selectedTrainingTypes.remove(type)
                                    } else {
                                        viewModel.selectedTrainingTypes.insert(type)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Question 3: Niveau de forme physique
                QuestionSection(
                    title: "Quel est votre niveau de forme physique général ?",
                    description: "Évaluez-vous sur une échelle de 1 à 10"
                ) {
                    VStack(spacing: 16) {
                        // Slider
                        VStack(spacing: 8) {
                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                Spacer()
                                Text("5")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                Spacer()
                                Text("10")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.userInformations.fitnessLevel ?? 5) },
                                    set: { viewModel.userInformations.fitnessLevel = Int($0) }
                                ),
                                in: 1...10,
                                step: 1
                            )
                            .accentColor(.yellow)
                            
                            HStack {
                                Text("Débutant")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                Spacer()
                                Text("Intermédiaire")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                                Spacer()
                                Text("Expert")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }
                        }
                        
                        // Niveau affiché
                        if let level = viewModel.userInformations.fitnessLevel {
                            Text("Niveau sélectionné: \(level)/10")
                                .font(.headline)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.yellow.opacity(0.1))
                                )
                        }
                    }
                }
                
                // Question 4: Blessures ou limitations
                QuestionSection(
                    title: "Avez-vous des blessures ou limitations physiques ?",
                    description: "Décrivez brièvement ou laissez vide si aucune"
                ) {
                    VStack(spacing: 12) {
                        TextField("Ex: Problème de genou, mal de dos...", text: $injuriesText, axis: .vertical)
                            .textFieldStyle(CustomTextFieldStyle())
                            .lineLimit(3...6)
                            .onChange(of: injuriesText) { newValue in
                                viewModel.userInformations.injuriesLimitations = newValue.isEmpty ? nil : newValue
                            }
                        
                        Text("Ces informations nous aideront à adapter vos entraînements")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer(minLength: 120) // Espace pour le footer
            }
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
        .onAppear {
            injuriesText = viewModel.userInformations.injuriesLimitations ?? ""
        }
    }
}

// MARK: - Frequency Card
struct FrequencyCard: View {
    let frequency: TrainingFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                
                Text(frequency.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
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

// MARK: - Training Type Card
struct TrainingTypeCard: View {
    let type: TrainingType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                
                Text(type.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 45, maxHeight: 45)
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

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.adaptiveCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.adaptiveBorderColor, lineWidth: 1)
                    )
            )
            .foregroundColor(Color.adaptiveTextPrimary)
    }
}

#Preview {
    ZStack {
        Color.adaptiveOnboardingBackground.ignoresSafeArea()
        OnboardingFitnessConditionView()
            .environmentObject(OnboardingViewModel())
    }
} 
