import SwiftUI

public struct EventCard: View {
    let event: Event
    
    public init(event: Event) {
        self.event = event
    }
    
    private var iconName: String {
        let type = event.eventType.lowercased()
        if type.contains("ritual") { return "book.closed.fill" }
        if type.contains("admin") { return "briefcase.fill" }
        if type.contains("congresso") { return "lanyardcard.fill" }
        if type.contains("filantropia") { return "calendar" }
        if type.contains("arrecada") { return "dollarsign.circle.fill" }
        return "star.fill"
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd 'de' MMMM 'às' HH:mm'.'"
        let formatted = formatter.string(from: event.scheduledDate)
        return formatted.prefix(1).capitalized + formatted.dropFirst()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.xs) {
                Image(systemName: iconName)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    
                Text(event.title)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(Typography.headline)
                    .foregroundColor(.accent)
            }
            
            Text(dateString)
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Divider()
                .background(Theme.textSecondary)
            
            HStack(alignment: .top, spacing: Spacing.xxs) {
                Text("Pauta:")
                    .font(Typography.subheadline)
                    .bold()
                    .foregroundColor(Theme.textPrimary)
                
                Text(event.notes?.isEmpty == false ? event.notes! : "Não informada")
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(Spacing.md)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.accent, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Reunião Ritualística", scheduledDate: Date(), eventType: "Ritualística", notes: "Apresentação de trabalho", createdAt: Date()))
        
        EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Reunião Administrativa", scheduledDate: Date(), eventType: "Administrativa", notes: "Planejamento de filantropia", createdAt: Date()))
        
        EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Congresso Estadual", scheduledDate: Date(), eventType: "Congresso", notes: "CGOD", createdAt: Date()))
        
        EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Filantropia", scheduledDate: Date(), eventType: "Filantropia", notes: "Filantropia na escola municipal", createdAt: Date()))
    }
    .padding()
    .background(Color(UIColor.systemBackground))
    .preferredColorScheme(.dark)
}
