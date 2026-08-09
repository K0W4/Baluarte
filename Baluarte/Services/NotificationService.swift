import Foundation
import UserNotifications

public struct NotificationService: @unchecked Sendable {
    public static let shared = NotificationService()

    private init() {}

    public func configure() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("Erro ao solicitar permissão de notificação: \(error.localizedDescription)")
            return false
        }
    }

    // Pede a permissão apenas quando o usuário demonstra querer um lembrete,
    // em vez de no primeiro lançamento, sem contexto.
    private func ensureAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return await requestAuthorization()
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }
    
    public func scheduleEventReminder(for eventName: String, date: Date, eventId: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Evento se aproximando!")
        
        // UX Copy: Welcoming, Motivating
        let copies = [
            "Estamos te esperando! Lembre-se do evento: \(eventName).",
            "Sua presença faz a diferença! O evento \(eventName) está quase começando.",
            "Tudo pronto? Nos vemos no \(eventName)!"
        ]
        
        content.body = copies.randomElement() ?? "Lembre-se do \(eventName)."
        content.sound = .default
        
        // Schedule for 24 hours before
        let reminderDate = date.addingTimeInterval(-86400) // 24h

        guard reminderDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "event_\(eventId)", content: content, trigger: trigger)

        Task {
            guard await ensureAuthorization() else { return }
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Erro ao agendar notificação: \(error.localizedDescription)")
            }
        }
    }
    
    public func cancelEventReminder(eventId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event_\(eventId)"])
    }
    
    // Método para testar a notificação na prática sem precisar alterar a hora
    public func scheduleTestNotification(inSeconds seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "Teste de Notificação 🚀"
        content.body = "Se você está vendo isso, o agendamento local está funcionando perfeitamente! Estamos te esperando! 🤝"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação de teste: \(error.localizedDescription)")
            } else {
                print("✅ Notificação de teste agendada para daqui a \(seconds) segundos.")
            }
        }
    }
}

private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {}

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
