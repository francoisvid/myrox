import SwiftUI

struct OnboardingEquipmentGymView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var gymNameText: String = ""
    @State private var gymLocationText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Question 1: Familiarité avec les stations HYROX
                QuestionSection(
                    title: "Êtes-vous familier avec les 8 stations HYROX ?",
                    description: "SkiErg, Sled Push/Pull, Burpees, RowErg, Farmers Carry, Sandbag Lunges, Wall Balls"
                ) {
                    HStack(spacing: 16) {
                        YesNoButton(
                            text: "Oui, je connais",
                            isSelected: viewModel.userInformations.familiarWithHyroxStations == true,
                            onTap: {
                                viewModel.userInformations.familiarWithHyroxStations = true
                            }
                        )
                        
                        YesNoButton(
                            text: "Non, à découvrir",
                            isSelected: viewModel.userInformations.familiarWithHyroxStations == false,
                            onTap: {
                                viewModel.userInformations.familiarWithHyroxStations = false
                            }
                        )
                    }
                }
                
                // Question 2: Exercices difficiles (si familier)
                if viewModel.userInformations.familiarWithHyroxStations == true {
                    QuestionSection(
                        title: "Quels exercices vous posent le plus de difficultés ?",
                        description: "Sélectionnez les stations que vous trouvez challenging"
                    ) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(hyroxStations, id: \.self) { station in
                                StationCard(
                                    stationName: station,
                                    isSelected: viewModel.selectedDifficultExercises.contains(station),
                                    onTap: {
                                        if viewModel.selectedDifficultExercises.contains(station) {
                                            viewModel.selectedDifficultExercises.remove(station)
                                        } else {
                                            viewModel.selectedDifficultExercises.insert(station)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Question 3: Accès à une salle
                QuestionSection(
                    title: "Avez-vous accès à une salle équipée pour l'entraînement HYROX ?",
                    description: "Ou au minimum avec du matériel de fitness fonctionnel"
                ) {
                    HStack(spacing: 16) {
                        YesNoButton(
                            text: "Oui",
                            isSelected: viewModel.userInformations.hasGymAccess == true,
                            onTap: {
                                viewModel.userInformations.hasGymAccess = true
                            }
                        )
                        
                        YesNoButton(
                            text: "Non",
                            isSelected: viewModel.userInformations.hasGymAccess == false,
                            onTap: {
                                viewModel.userInformations.hasGymAccess = false
                            }
                        )
                    }
                }
                
                // Question 4: Détails de la salle (si accès)
                if viewModel.userInformations.hasGymAccess == true {
                    QuestionSection(
                        title: "Dans quelle salle vous entraînez-vous ?",
                        description: "Nom et localisation (optionnel)"
                    ) {
                        VStack(spacing: 12) {
                            TextField("Nom de votre salle de sport", text: $gymNameText)
                                .textFieldStyle(CustomTextFieldStyle())
                                .foregroundColor(Color.adaptiveTextPrimary)
                                .onChange(of: gymNameText) { newValue in
                                    viewModel.userInformations.gymName = newValue.isEmpty ? nil : newValue
                                }
                            
                            TextField("Ville ou adresse", text: $gymLocationText)
                                .textFieldStyle(CustomTextFieldStyle())
                                .foregroundColor(Color.adaptiveTextPrimary)
                                .onChange(of: gymLocationText) { newValue in
                                    viewModel.userInformations.gymLocation = newValue.isEmpty ? nil : newValue
                                }
                        }
                    }
                    
                    // Question 5: Équipements disponibles
                    QuestionSection(
                        title: "Quels équipements HYROX sont disponibles ?",
                        description: "Sélectionnez tous ceux auxquels vous avez accès"
                    ) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(HyroxEquipment.allCases, id: \.self) { equipment in
                                EquipmentCard(
                                    equipment: equipment,
                                    isSelected: viewModel.selectedEquipment.contains(equipment),
                                    onTap: {
                                        if viewModel.selectedEquipment.contains(equipment) {
                                            viewModel.selectedEquipment.remove(equipment)
                                        } else {
                                            viewModel.selectedEquipment.insert(equipment)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                
                Spacer(minLength: 120) // Espace pour le footer
            }
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
        .onAppear {
            gymNameText = viewModel.userInformations.gymName ?? ""
            gymLocationText = viewModel.userInformations.gymLocation ?? ""
        }
    }
}

// MARK: - Station Card
struct StationCard: View {
    let stationName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: stationIcon(for: stationName))
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                
                Text(stationDisplayName(for: stationName))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
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

// MARK: - Equipment Card
struct EquipmentCard: View {
    let equipment: HyroxEquipment
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: equipmentIcon(for: equipment))
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .yellow)
                
                Text(equipment.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .black : Color.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Badge pour stations officielles HYROX
                if equipment.isHyroxStation {
                    Text("HYROX")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(isSelected ? .yellow : .black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.black.opacity(0.2) : Color.yellow)
                        )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
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

// MARK: - Helper Functions

private let hyroxStations = [
    "SKIERG",
    "SLED_PUSH",
    "SLED_PULL",
    "BURPEES_BROAD_JUMP",
    "ROWERG",
    "FARMERS_CARRY",
    "SANDBAG_LUNGES",
    "WALL_BALLS"
]

private func stationDisplayName(for station: String) -> String {
    switch station {
    case "SKIERG": return "SkiErg"
    case "SLED_PUSH": return "Sled Push"
    case "SLED_PULL": return "Sled Pull"
    case "BURPEES_BROAD_JUMP": return "Burpees Broad Jump"
    case "ROWERG": return "RowErg"
    case "FARMERS_CARRY": return "Farmers Carry"
    case "SANDBAG_LUNGES": return "Sandbag Lunges"
    case "WALL_BALLS": return "Wall Balls"
    default: return station
    }
}

private func stationIcon(for station: String) -> String {
    switch station {
    case "SKIERG": return "figure.skiing.downhill"
    case "SLED_PUSH": return "figure.strengthtraining.traditional"
    case "SLED_PULL": return "figure.strengthtraining.traditional"
    case "BURPEES_BROAD_JUMP": return "figure.jumprope"
    case "ROWERG": return "figure.indoor.rowing"
    case "FARMERS_CARRY": return "dumbbell"
    case "SANDBAG_LUNGES": return "figure.walk"
    case "WALL_BALLS": return "volleyball"
    default: return "dumbbell"
    }
}

private func equipmentIcon(for equipment: HyroxEquipment) -> String {
    switch equipment {
    case .skierg: return "figure.skiing.downhill"
    case .sled: return "figure.strengthtraining.traditional"
    case .rowerg: return "figure.indoor.rowing"
    case .wallBalls: return "volleyball"
    case .kettlebells: return "dumbbell"
    case .dumbbells: return "dumbbell"
    case .sandbag: return "bag"
    case .boxJump: return "square.stack.3d.up"
    case .pullUpBar: return "figure.strengthtraining.traditional"
    case .farmers: return "dumbbell"
    }
}

#Preview {
    ZStack {
        Color.adaptiveOnboardingBackground.ignoresSafeArea()
        OnboardingEquipmentGymView()
            .environmentObject(OnboardingViewModel())
    }
} 
