import Foundation
import UserNotifications

public struct NotificationService: @unchecked Sendable {
    public static let shared = NotificationService()
    
    private init() {}
    
    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("Erro ao solicitar permissão de notificação: \(error.localizedDescription)")
            return false
        }
    }
    
    public func scheduleEventReminder(for eventName: String, date: Date, eventId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Evento se aproximando!"
        
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
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação: \(error.localizedDescription)")
            }
        }
    }
    
    public func cancelEventReminder(eventId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event_\(eventId)"])
    }
}
