import SwiftUI

struct OnboardingPlanningView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var showDatePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Question 1: Fréquence d'entraînement souhaitée
                QuestionSection(
                    title: "Combien de fois par semaine souhaitez-vous vous entraîner ?",
                    description: "Votre objectif idéal pour l'entraînement HYROX"
                ) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(TrainingFrequency.allCases, id: \.self) { frequency in
                            FrequencyCard(
                                frequency: frequency,
                                isSelected: viewModel.userInformations.preferredTrainingFrequency == frequency,
                                onTap: {
                                    viewModel.userInformations.preferredTrainingFrequency = frequency
                                }
                            )
                        }
                    }
                }
                
                // Question 2: Durée des séances
                QuestionSection(
                    title: "Quelle est la durée souhaitée de vos séances ?",
                    description: "Incluant échauffement et récupération"
                ) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(SessionDuration.allCases, id: \.self) { duration in
                            DurationCard(
                                duration: duration,
                                isSelected: viewModel.userInformations.preferredSessionDuration == duration,
                                onTap: {
                                    viewModel.userInformations.preferredSessionDuration = duration
                                }
                            )
                        }
                    }
                }
                
                // Question 3: Créneaux préférés
                QuestionSection(
                    title: "Préférez-vous vous entraîner le matin, midi ou soir ?",
                    description: "Sélectionnez votre créneau idéal"
                ) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(TrainingTime.allCases, id: \.self) { time in
                            TimeSlotCard(
                                trainingTime: time,
                                isSelected: viewModel.userInformations.preferredTrainingTime == time,
                                onTap: {
                                    viewModel.userInformations.preferredTrainingTime = time
                                }
                            )
                        }
                    }
                }
                
                // Question 4: Date de compétition cible
                QuestionSection(
                    title: "Avez-vous une date de compétition cible ?",
                    description: "Cela nous aidera à structurer votre préparation (optionnel)"
                ) {
                    VStack(spacing: 16) {
                        // Bouton pour ajouter/modifier la date
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.yellow)
                                
                                if let date = viewModel.userInformations.targetCompetitionDate {
                                    Text(formatDate(date))
                                        .foregroundColor(Color.adaptiveTextPrimary)
                                } else {
                                    Text("Sélectionner une date")
                                        .foregroundColor(Color.adaptiveTextSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.adaptiveTextSecondary)
                            }
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
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Bouton pour supprimer la date
                        if viewModel.userInformations.targetCompetitionDate != nil {
                            Button("Supprimer la date") {
                                viewModel.userInformations.targetCompetitionDate = nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        
                        // Informations supplémentaires
                        VStack(spacing: 8) {
                            if let date = viewModel.userInformations.targetCompetitionDate {
                                let weeksUntil = weeksUntilDate(date)
                                if weeksUntil > 0 {
                                    Text("📅 \(weeksUntil) semaines de préparation")
                                        .font(.subheadline)
                                        .foregroundColor(.yellow)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.yellow.opacity(0.1))
                                        )
                                }
                            }
                            
                            Text("Une date cible permet d'optimiser votre plan d'entraînement avec une progression adaptée")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                Spacer(minLength: 120) // Espace pour le footer
            }
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: Binding(
                    get: { viewModel.userInformations.targetCompetitionDate ?? Date().addingTimeInterval(86400 * 30) },
                    set: { viewModel.userInformations.targetCompetitionDate = $0 }
                ),
                isPresented: $showDatePicker
            )
        }
    }
}


// MARK: - Duration Card
struct DurationCard: View {
    let duration: SessionDuration
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                
                Text(duration.displayName)
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

// MARK: - Time Slot Card
struct TimeSlotCard: View {
    let trainingTime: TrainingTime
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: trainingTime.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                
                Text(trainingTime.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
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

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Sélectionnez votre date de compétition cible")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                DatePicker(
                    "Date de compétition",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                // Boutons d'action
                HStack(spacing: 16) {
                    Button("Annuler") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.adaptiveCardBackground)
                    .foregroundColor(Color.adaptiveTextPrimary)
                    .cornerRadius(8)
                    
                    Button("Confirmer") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Date de compétition")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium]) // Réduit la taille de la modal
    }
}

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.locale = Locale(identifier: "fr_FR")
    return formatter.string(from: date)
}

private func weeksUntilDate(_ date: Date) -> Int {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.weekOfYear], from: now, to: date)
    return max(0, components.weekOfYear ?? 0)
}

#Preview {
    ZStack {
        Color.adaptiveOnboardingBackground.ignoresSafeArea()
        OnboardingPlanningView()
            .environmentObject(OnboardingViewModel())
    }
} 