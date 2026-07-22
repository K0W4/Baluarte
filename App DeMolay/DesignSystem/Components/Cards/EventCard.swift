import SwiftUI

public struct EventCard: View {
    let event: Event
    let isUserConfirmed: Bool
    let onConfirmAttendance: (() -> Void)?
    
    public init(event: Event, isUserConfirmed: Bool = false, onConfirmAttendance: (() -> Void)? = nil) {
        self.event = event
        self.isUserConfirmed = isUserConfirmed
        self.onConfirmAttendance = onConfirmAttendance
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
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd 'de' MMMM 'às' HH:mm'.'"
        return formatter
    }()
    
    private var dateString: String {
        let formatted = Self.dateFormatter.string(from: event.scheduledDate)
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
                    .font(Typography.body)
                    .foregroundColor(Theme.accent)
            }
            
            Divider()
                .background(Theme.border)
            
            HStack(alignment: .top, spacing: Spacing.xxs) {
                Text("Data:")
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textPrimary)
                
                Text(dateString)
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            
            if let notes = event.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: Spacing.xxs) {
                    Text("Detalhes:")
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(notes)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: isUserConfirmed ? .rigid : .medium)
                generator.impactOccurred()
                onConfirmAttendance?()
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: isUserConfirmed ? "checkmark.circle.fill" : "person.crop.circle.badge.plus")
                        .font(Typography.caption1)
                    Text(isUserConfirmed ? "Presença Confirmada" : "Confirmar Presença")
                        .font(Typography.caption1)
                }
                .foregroundColor(isUserConfirmed ? Theme.success : Theme.accent)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(isUserConfirmed ? Theme.success.opacity(0.15) : Theme.accent.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isUserConfirmed ? "Cancelar presença no evento \(event.title)" : "Confirmar presença no evento \(event.title)")
        }
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Reunião Ritualística", scheduledDate: Date(), eventType: "Ritualística", notes: "Apresentação de trabalho", createdAt: Date()))
            
            EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Reunião Administrativa", scheduledDate: Date(), eventType: "Administrativa", notes: "Planejamento de filantropia", createdAt: Date()))
            
            EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Congresso Estadual", scheduledDate: Date(), eventType: "Congresso", notes: "CGOD", createdAt: Date()))
            
            EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Filantropia", scheduledDate: Date(), eventType: "Filantropia", notes: "Filantropia na escola municipal", createdAt: Date()))
            
            EventCard(event: Event(id: UUID(), chapterId: UUID(), title: "Lanche Coletivo", scheduledDate: Date(), eventType: "Lanche", notes: "Lanche depois da reunião", createdAt: Date()))
        }
        .padding(Spacing.screenEdgePadding)
    }
}
