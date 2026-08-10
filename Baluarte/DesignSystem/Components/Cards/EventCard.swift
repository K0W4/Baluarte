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
        if type.contains("filantropia") { return "hands.and.sparkles.fill" }
        if type.contains("monet") { return "dollarsign.circle.fill" }
        return "star.fill"
    }
    
    private var dateString: String {
        // O formato sai do sistema, não de um padrão escrito à mão: o `.capitalized` que
        // havia aqui também quebra em idiomas que não capitalizam dia da semana.
        event.scheduledDate.formatted(
            .dateTime.weekday(.wide).day().month(.wide).hour().minute()
        )
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
                    .foregroundColor(Theme.accentText)
            }
            
            Divider()
                .background(Theme.border)
            
            HStack(alignment: .top, spacing: Spacing.xxs) {
                Text("\(String(localized: "Data")):")
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textPrimary)
                
                Text(dateString)
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            
            if let notes = event.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: Spacing.xxs) {
                    Text("\(String(localized: "Detalhes")):")
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(notes)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Preenchido é a ação a tomar; confirmado já é estado, e estado não grita.
            // Além de devolver a hierarquia, isso tira o ícone verde de cima do vermelho —
            // o par que some justamente para quem tem daltonismo vermelho-verde.
            AttendanceButton(isConfirmed: isUserConfirmed, title: event.title) {
                HapticManager.shared.impact(style: isUserConfirmed ? .rigid : .medium)
                onConfirmAttendance?()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), \(event.eventType), \(dateString), \(event.confirmedAttendees?.count ?? 0) presenças")
        .accessibilityHint("Toque para ver detalhes do evento")
        .accessibilityAddTraits(.isButton)
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
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
