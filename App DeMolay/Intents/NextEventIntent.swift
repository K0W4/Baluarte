import AppIntents
import Foundation
import SwiftUI

public struct NextEventIntent: AppIntent {
    public static var title: LocalizedStringResource = "Próximo Evento do Capítulo"
    public static var description = IntentDescription("Verifica qual é o próximo evento agendado do Capítulo.")
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let chapterId = UserDefaultsManager.shared.currentChapterId else {
            return .result(dialog: "Você precisa estar autenticado para ver o próximo evento.")
        }
        
        let events = try await Services.event.fetchEvents(for: chapterId)
        let upcomingEvents = events.filter { $0.scheduledDate > Date() }.sorted { $0.scheduledDate < $1.scheduledDate }
        
        guard let nextEvent = upcomingEvents.first else {
            return .result(dialog: "Não há próximos eventos agendados para o Capítulo.")
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd 'de' MMMM 'às' HH:mm"
        let dateStr = formatter.string(from: nextEvent.scheduledDate)
        
        let dialogStr = "O próximo evento é \(nextEvent.title) e acontecerá \(dateStr)."
        
        return .result(
            dialog: IntentDialog(stringLiteral: dialogStr),
            view: NextEventSnippetView(event: nextEvent)
        )
    }
}

public struct NextEventSnippetView: View {
    let event: Event
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Próximo Evento")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(event.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.accent)
                
                Text(event.scheduledDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(event.scheduledDate, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let notes = event.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(Theme.accent)
                    
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
}
