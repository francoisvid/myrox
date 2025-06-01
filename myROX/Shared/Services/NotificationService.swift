import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private override init() {
        super.init()
        setupNotificationDelegate()
    }
    
    // MARK: - Configuration
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Autorisation
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Erreur lors de la demande d'autorisation de notification: \(error)")
            return false
        }
    }
    
    // MARK: - Notification de fin de séance
    func scheduleWorkoutCompletionNotification(for workout: Workout) async {
        let center = UNUserNotificationCenter.current()
        
        // Supprimer les notifications précédentes de même type
        center.removePendingNotificationRequests(withIdentifiers: ["workout-completion"])
        
        let content = UNMutableNotificationContent()
        content.title = "Séance terminée ! 🎉"
        content.body = "Vos statistiques sont prêtes à être partagées"
        content.sound = .default
        
        // Ajouter des données personnalisées
        content.userInfo = [
            "type": "workout-completion",
            "workoutId": workout.id.uuidString,
            "templateName": workout.templateName ?? "Séance",
            "duration": workout.totalDuration,
            "distance": workout.totalDistance
        ]
        
        // Programmer la notification pour dans 2 secondes (laisser le temps à la vue de s'afficher)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "workout-completion",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("Notification de fin de séance programmée pour dans 2 secondes")
        } catch {
            print("Erreur lors de la programmation de la notification: \(error)")
        }
    }
    
    // MARK: - Notification de nouveau record
    func schedulePersonalRecordNotification(exerciseName: String, recordType: String) async {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Nouveau record personnel ! 🏆"
        content.body = "Félicitations ! Vous avez battu votre record sur \(exerciseName)"
        content.sound = .default
        
        content.userInfo = [
            "type": "personal-record",
            "exerciseName": exerciseName,
            "recordType": recordType
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "personal-record-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("Notification de record personnel programmée pour \(exerciseName)")
        } catch {
            print("Erreur lors de la programmation de la notification de record: \(error)")
        }
    }
    
    // MARK: - Vérifier les autorisations
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Debug
    func checkPendingNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        print("🔔 Notifications en attente: \(pending.count)")
        for notification in pending {
            print("  - \(notification.identifier): \(notification.content.title)")
            if let trigger = notification.trigger as? UNTimeIntervalNotificationTrigger {
                print("    Délai: \(trigger.timeInterval)s")
            }
        }
    }
    
    // MARK: - Notification de fin de séance depuis la Watch
    func scheduleWorkoutCompletionFromWatchNotification(for workout: Workout) async {
        let center = UNUserNotificationCenter.current()
        
        // Supprimer les notifications précédentes de même type
        center.removePendingNotificationRequests(withIdentifiers: ["workout-completion-watch"])
        
        let content = UNMutableNotificationContent()
        content.title = "Séance Apple Watch terminée ! ⌚"
        content.body = "Synchronisée depuis votre Apple Watch - Statistiques disponibles"
        content.sound = .default
        
        // Ajouter des données personnalisées
        content.userInfo = [
            "type": "workout-completion-watch",
            "workoutId": workout.id.uuidString,
            "templateName": workout.templateName ?? "Séance",
            "duration": workout.totalDuration,
            "distance": workout.totalDistance,
            "source": "watch"
        ]
        
        // Programmer la notification immédiatement (pas de vue à afficher dans ce cas)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "workout-completion-watch",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("📱⌚ Notification de fin de séance Apple Watch programmée")
        } catch {
            print("Erreur lors de la programmation de la notification Watch: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Cette méthode permet d'afficher les notifications même quand l'app est en premier plan
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 Notification reçue en premier plan: \(notification.request.content.title)")
        
        // Afficher la notification avec son, badge et bannière même en premier plan
        completionHandler([.banner, .sound, .badge])
    }
    
    // Cette méthode gère les interactions avec les notifications
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 Notification tapée: \(userInfo)")
        
        // Déléguer la navigation au service spécialisé
        Task { @MainActor in
            NotificationNavigationService.shared.handleNotificationTap(userInfo: userInfo)
        }
        
        // Traiter selon le type de notification (logs pour debug)
        if let type = userInfo["type"] as? String {
            switch type {
            case "workout-completion":
                print("🏋️ Notification de fin de séance tapée - Ouverture de la modale")
            case "workout-completion-watch":
                print("⌚ Notification de fin de séance Apple Watch tapée - Ouverture de la modale")
            case "personal-record":
                print("🏆 Notification de record personnel tapée - Ouverture des statistiques")
            default:
                break
            }
        }
        
        completionHandler()
    }
}
