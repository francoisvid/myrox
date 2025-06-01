import SwiftUI
import Foundation
import UIKit
import Photos

@MainActor
class WorkoutSharingService: ObservableObject {
    static let shared = WorkoutSharingService()
    
    private init() {}
    
    // MARK: - Génération de la carte de partage
    func generateShareableWorkoutCard(for workout: Workout, isCompact: Bool = false) -> some View {
        WorkoutShareCard(workout: workout, isCompact: isCompact)
    }
    
    // MARK: - Partage natif iOS
    func shareWorkout(_ workout: Workout, from sourceView: UIView? = nil) {
        let shareText = generateShareText(for: workout)
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Configuration pour iPad
        if let popover = activityController.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                // Utiliser la fenêtre principale si pas de source view
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    popover.sourceView = window.rootViewController?.view
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }
            }
        }
        
        // Trouver le contrôleur de vue le plus approprié pour présenter
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            var presentingController = window.rootViewController
            
            // Parcourir la hiérarchie pour trouver le contrôleur présenté le plus récent
            while let presentedViewController = presentingController?.presentedViewController {
                presentingController = presentedViewController
            }
            
            // Vérifier que le contrôleur peut présenter une nouvelle vue
            guard let controller = presentingController, !controller.isBeingDismissed else {
                print("❌ Impossible de présenter le partage : contrôleur indisponible")
                return
            }
            
            print("📱 Présentation du partage depuis: \(type(of: controller))")
            controller.present(activityController, animated: true)
        }
    }
    
    // MARK: - Partage Instagram
    func shareToInstagramStories(_ workout: Workout, showAllExercises: Bool = false, colorScheme: ColorScheme? = nil) {
        // Générer l'image de la carte
        Task {
            if let image = await generateWorkoutImage(for: workout, showAllExercises: showAllExercises, colorScheme: colorScheme) {
                // Sauvegarder dans Photos et ouvrir Instagram
                await saveImageAndOpenInstagram(image)
            } else {
                print("❌ Impossible de générer l'image")
                shareWorkout(workout)
            }
        }
    }
    
    private func saveImageAndOpenInstagram(_ image: UIImage) async {
        do {
            // Demander permission Photos si nécessaire
            let status = await requestPhotosPermission()
            guard status else {
                print("❌ Permission Photos refusée")
                return
            }
            
            // Sauvegarder l'image dans Photos
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // Attendre un peu pour que la sauvegarde se termine
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
            
            // Afficher un message à l'utilisateur
            await showInstagramInstructions()
            
            // Ouvrir Instagram si disponible
            if isInstagramInstalled() {
                if let url = URL(string: "instagram://camera") {
                    await UIApplication.shared.open(url)
                }
            }
            
        } catch {
            print("❌ Erreur lors de la sauvegarde: \(error)")
        }
    }
    
    private func requestPhotosPermission() async -> Bool {
        // Pour simplifier, on utilise UIImageWriteToSavedPhotosAlbum qui demande automatiquement la permission
        // Dans une vraie app, on utiliserait PHPhotoLibrary.requestAuthorization
        return true
    }
    
    private func showInstagramInstructions() async {
        // Afficher une alerte avec instructions
        await MainActor.run {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                let alert = UIAlertController(
                    title: "📸 Image sauvegardée !",
                    message: "Votre carte d'entraînement a été sauvegardée dans Photos.\n\nInstagram va s'ouvrir - vous pourrez la partager en story depuis votre galerie !",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                
                // Trouver le bon contrôleur pour présenter l'alerte
                var presentingController = rootViewController
                while let presentedViewController = presentingController.presentedViewController {
                    presentingController = presentedViewController
                }
                
                presentingController.present(alert, animated: true)
            }
        }
    }
    
    private func isInstagramInstalled() -> Bool {
        guard let url = URL(string: "instagram://camera") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    // MARK: - Génération d'image
    private func generateWorkoutImage(for workout: Workout, showAllExercises: Bool = false, colorScheme: ColorScheme? = nil) async -> UIImage? {
        // Détecter le thème actuel
        let isDarkMode: Bool
        if let colorScheme = colorScheme {
            isDarkMode = colorScheme == .dark
        } else {
            isDarkMode = await MainActor.run {
                UITraitCollection.current.userInterfaceStyle == .dark
            }
        }
        
        // Créer une vue conteneur qui s'adapte au thème
        let containerView = ZStack {
            // Fond qui s'adapte au thème
            Rectangle()
                .fill(isDarkMode ? Color(.systemBackground) : Color.white)
                .frame(width: 380, height: 640)
            
            // Carte centrée avec padding horizontal
            WorkoutShareCard(workout: workout, isCompact: showAllExercises)
                .padding(.horizontal, 16)
        }
        .frame(width: 380, height: 640)
        .clipped()
        .environment(\.colorScheme, isDarkMode ? .dark : .light) // Forcer le thème
        
        let renderer = ImageRenderer(content: containerView)
        renderer.scale = 3.0 // Haute résolution
        
        // Configuration explicite pour le thème
        if let cgImage = renderer.cgImage {
            let uiImage = UIImage(cgImage: cgImage, scale: renderer.scale, orientation: .up)
            return uiImage
        }
        
        // Fallback avec method adaptée au thème
        if let uiImage = renderer.uiImage {
            return isDarkMode ? createImageWithDarkBackground(from: uiImage) : createImageWithWhiteBackground(from: uiImage)
        }
        
        return nil
    }
    
    private func createImageWithWhiteBackground(from image: UIImage) -> UIImage? {
        let size = image.size
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, true, image.scale)
        
        // Remplir avec blanc
        UIColor.white.setFill()
        UIRectFill(rect)
        
        // Dessiner l'image par-dessus
        image.draw(in: rect)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    private func createImageWithDarkBackground(from image: UIImage) -> UIImage? {
        let size = image.size
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, true, image.scale)
        
        // Remplir avec la couleur de fond sombre du système
        UIColor.systemBackground.setFill()
        UIRectFill(rect)
        
        // Dessiner l'image par-dessus
        image.draw(in: rect)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    // MARK: - Génération du texte de partage
    func generateShareText(for workout: Workout) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        
        let durationFormatter = DateComponentsFormatter()
        durationFormatter.allowedUnits = [.minute, .second]
        durationFormatter.unitsStyle = .abbreviated
        
        var text = "🏋️‍♂️ Séance terminée !\n\n"
        
        if let templateName = workout.templateName {
            text += "📋 \(templateName)\n"
        }
        
        text += "📅 \(formatter.string(from: workout.startedAt))\n"
        
        if workout.totalDuration > 0 {
            text += "⏱️ Durée: \(durationFormatter.string(from: workout.totalDuration) ?? "N/A")\n"
        }
        
        if workout.totalDistance > 0 {
            text += "📏 Distance totale: \(Int(workout.totalDistance))m\n"
        }
        
        // Ajouter les exercices avec leurs performances
        let groupedExercises = Dictionary(grouping: workout.performances) { $0.exerciseName }
        
        if !groupedExercises.isEmpty {
            text += "\n💪 Exercices:\n"
            
            for (exerciseName, exercises) in groupedExercises {
                let completedExercises = exercises.filter { $0.completedAt != nil }
                if !completedExercises.isEmpty {
                    text += "• \(exerciseName)\n"
                    
                    for (index, exercise) in completedExercises.enumerated() {
                        let roundText = completedExercises.count > 1 ? " (Round \(exercise.round))" : ""
                        let duration = durationFormatter.string(from: exercise.duration) ?? "N/A"
                        text += "  \(index + 1). \(duration)\(roundText)"
                        
                        if exercise.distance > 0 {
                            text += " - \(Int(exercise.distance))m"
                        }
                        
                        if exercise.repetitions > 0 {
                            text += " - \(exercise.repetitions) reps"
                        }
                        
                        text += "\n"
                    }
                }
            }
        }
        
        // Ajouter les records personnels
        let personalRecords = workout.performances.filter { $0.isPersonalRecord }
        if !personalRecords.isEmpty {
            text += "\n🏆 Nouveaux records personnels:\n"
            for record in personalRecords {
                text += "• \(record.exerciseName)\n"
            }
        }
        
        text += "\n#myROX #fitness #workout"
        
        return text
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Vue de la carte partageable
struct WorkoutShareCard: View {
    let workout: Workout
    let isCompact: Bool
    
    // Initialiseur par défaut
    init(workout: Workout, isCompact: Bool = false) {
        self.workout = workout
        self.isCompact = isCompact
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo et branding
            VStack(spacing: 8) {
                Text("MyROX")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // En-tête workout
            VStack(spacing: 8) {
                Text(workout.templateName ?? "Nom de la séance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(formatDate(workout.startedAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Statistiques principales
            HStack(spacing: 10) {
                StatBubble(
                    icon: "clock.fill",
                    value: formatDuration(workout.totalDuration),
                    label: "Durée"
                )
                
                if workout.totalDistance > 0 {
                    StatBubble(
                        icon: "ruler.fill",
                        value: "\(Int(workout.totalDistance))m",
                        label: "Distance"
                    )
                }
                
                StatBubble(
                    icon: "flame.fill",
                    value: "\(workout.performances.filter { $0.completedAt != nil }.count)",
                    label: "Exercices"
                )
            }
            
            // Liste des exercices
            VStack(spacing: isCompact ? 4 : 8) {
                let allPerformances = workout.performances.filter { $0.completedAt != nil }
                    .sorted { (ex1, ex2) in
                        if ex1.round == ex2.round {
                            return ex1.order < ex2.order
                        }
                        return ex1.round < ex2.round
                    }
                
                let performancesToShow = isCompact ? Array(allPerformances.prefix(6)) : Array(allPerformances.prefix(4))
                
                // En-tête des colonnes en mode compact
                if isCompact && !performancesToShow.isEmpty {
                    HStack {
                        Text("Exercice")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Temps")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                        
                        Text("Dist.")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 75, alignment: .center)
                        
                        Text("Reps")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .center)
                        
                        Text("PR")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .center)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
                }
                
                ForEach(Array(performancesToShow.enumerated()), id: \.offset) { index, exercise in
                    WorkoutShareExerciseRow(
                        exerciseName: exercise.exerciseName,
                        exercises: [exercise], // Passer l'exercice individuel
                        isCompact: isCompact
                    )
                }
                
                // Affichage des exercices supplémentaires
                let remainingExercises = isCompact ? max(0, allPerformances.count - 6) : max(0, allPerformances.count - 4)
                if remainingExercises > 0 {
                    let isPlural = remainingExercises > 1
                    
                    HStack {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("et \(remainingExercises) autre\(isPlural ? "s" : "") exercice\(isPlural ? "s" : "")")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        
                        Image(systemName: "ellipsis")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.top, 4)
                }
            }
            
            // Records personnels
            if workout.performances.contains(where: { $0.isPersonalRecord }) {
                VStack {
                    HStack {
                        Text("NOUVEAU RECORD!")
                            .font(.caption)
                            .fontWeight(.bold)
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                    }
                    .foregroundColor(.orange)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(12)
            }
            
            // Hashtags
            Text("#myROX #hyrox #fitness #workout")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.label).opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.yellow.opacity(0.6), .orange.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }

    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Composant de statistique
struct StatBubble: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(minHeight: 40)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(minWidth: 60, maxHeight: 75)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct WorkoutShareExerciseRow: View {
    let exerciseName: String
    let exercises: [WorkoutExercise]
    let isCompact: Bool
    
    // Initialiseur par défaut
    init(exerciseName: String, exercises: [WorkoutExercise], isCompact: Bool = false) {
        self.exerciseName = exerciseName
        self.exercises = exercises
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack {
            // Nom de l'exercice
            Text(exerciseName)
                .font(isCompact ? .caption : .body)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Durée
            Text(formatDuration(exercises[0].duration))
                .font(isCompact ? .caption2 : .body)
                .foregroundColor(.primary)
                .frame(width: 50, alignment: .trailing)
            
            // Distance
            Group {
                if exercises[0].distance > 0 {
                    Text("\(Int(exercises[0].distance))m")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 3)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(3)
                } else {
                    Text("-")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 65, alignment: .center)
            
            // Répétitions
            Group {
                if exercises[0].repetitions > 0 {
                    Text("\(exercises[0].repetitions)")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 3)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(3)
                } else {
                    Text("-")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 35, alignment: .center)
            
            // Trophée record
            Group {
                if exercises[0].isPersonalRecord {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(isCompact ? .caption2 : .caption)
                } else {
                    Text("")
                }
            }
            .frame(width: 20, alignment: .center)
        }
        .padding(.horizontal, isCompact ? 8 : 16)
        .padding(.vertical, isCompact ? 2 : 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview("Carte normale") {
    // Créer un workout de test
    let workout = Workout()
    workout.templateName = "Séance HYROX Test"
    workout.startedAt = Date()
    workout.totalDuration = 1845 // 30:45
    workout.totalDistance = 2500
    
    // Créer des exercices de test
    let exercise1 = WorkoutExercise(exerciseName: "Ski Erg", round: 1, order: 0)
    exercise1.duration = 245 // 4:05
    exercise1.distance = 1000
    exercise1.completedAt = Date()
    exercise1.isPersonalRecord = true
    
    let exercise2 = WorkoutExercise(exerciseName: "Burpees Broad Jump", round: 1, order: 1)
    exercise2.duration = 180 // 3:00
    exercise2.repetitions = 80
    exercise2.completedAt = Date()
    
    let exercise3 = WorkoutExercise(exerciseName: "Sled Push", round: 1, order: 2)
    exercise3.duration = 195 // 3:15
    exercise3.distance = 50
    exercise3.completedAt = Date()
    
    let exercise4 = WorkoutExercise(exerciseName: "Farmers Carry", round: 1, order: 3)
    exercise4.duration = 125 // 2:05
    exercise4.distance = 200
    exercise4.completedAt = Date()
    exercise4.isPersonalRecord = true
    
    workout.performances = [exercise1, exercise2, exercise3, exercise4]
    
    return WorkoutShareCard(workout: workout)
        .padding()
}

#Preview("Carte compacte") {
    // Créer un workout de test avec plus d'exercices
    let workout = Workout()
    workout.templateName = "Séance HYROX Complète"
    workout.startedAt = Date()
    workout.totalDuration = 2845 // 47:25
    workout.totalDistance = 4500
    
    // Créer 6 exercices pour tester le mode compact
    let exercises = [
        ("Ski Erg", 245, 1000, 0, true),
        ("Burpees Broad Jump", 180, 0, 80, false),
        ("Sled Push", 195, 50, 0, false),
        ("Farmers Carry", 125, 200, 0, true),
        ("Wall Balls", 165, 0, 100, false),
        ("Sandbag Lunges", 220, 100, 0, false)
    ]
    
    var workoutExercises: [WorkoutExercise] = []
    for (index, (name, duration, distance, reps, isRecord)) in exercises.enumerated() {
        let exercise = WorkoutExercise(exerciseName: name, round: 1, order: index)
        exercise.duration = TimeInterval(duration)
        exercise.distance = Double(distance)
        exercise.repetitions = reps
        exercise.completedAt = Date()
        exercise.isPersonalRecord = isRecord
        workoutExercises.append(exercise)
    }
    
    workout.performances = workoutExercises
    
    return WorkoutShareCard(workout: workout, isCompact: true)
        .padding()
} 
