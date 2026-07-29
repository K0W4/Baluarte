import AppIntents
import Foundation
import Supabase
import Auth

public struct ConfirmAttendanceIntent: AppIntent {
    public static var title: LocalizedStringResource = "Confirmar presença no capítulo"
    public static var description = IntentDescription("Confirma sua presença no próximo evento agendado do Capítulo.")
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let chapterId = await UserDefaultsManager.shared.currentChapterId,
              let userId = await UserDefaultsManager.shared.currentUserId else {
            return .result(dialog: "Você precisa estar autenticado para confirmar presença.")
        }
        
        let events = try await Services.event.fetchEvents(for: chapterId)
        let upcomingEvents = events.filter { $0.scheduledDate > Date() }.sorted { $0.scheduledDate < $1.scheduledDate }
        
        guard let nextEvent = upcomingEvents.first else {
            return .result(dialog: "Não há próximos eventos agendados para confirmar presença.")
        }
        
        
        try await Services.event.confirmAttendance(eventId: nextEvent.id, userId: userId)
        
        return .result(dialog: "Sua presença foi confirmada para o evento \(nextEvent.title).")
    }
}
