import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Event Provider
struct EventProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> EventEntry {
        EventEntry(date: Date(), event: Event.mock, isUserConfirmed: false, errorMessage: nil, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> EventEntry {
        EventEntry(date: Date(), event: Event.mock, isUserConfirmed: true, errorMessage: nil, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<EventEntry> {
        let membershipId = configuration.chapter?.id.uuidString
        var nextEvent: Event? = nil
        var fetchError: String? = nil

        do {
            nextEvent = try await WidgetDataManager.shared
                .fetchUpcomingEvents(membershipId: membershipId).first
        } catch {
            fetchError = error.localizedDescription
            nextEvent = WidgetDataManager.shared.cachedEvents(membershipId: membershipId)?.first
        }

        let entry = EventEntry(
            date: Date(),
            event: nextEvent,
            isUserConfirmed: isConfirmed(nextEvent, membershipId: membershipId),
            errorMessage: fetchError,
            configuration: configuration
        )
        return Timeline(entries: [entry], policy: .after(Self.nextRefresh))
    }

    /// A presença é do vínculo, então o widget do segundo Capítulo tem de conferir o
    /// vínculo daquele Capítulo — não o que está aberto no app.
    private func isConfirmed(_ event: Event?, membershipId: String?) -> Bool {
        guard let attendees = event?.confirmedAttendees,
              let resolved = WidgetDataManager.shared.resolve(membershipId: membershipId),
              let membershipUUID = UUID(uuidString: resolved.membershipId)
        else { return false }
        return attendees.contains(membershipUUID)
    }

    /// Quinze minutos, e sem `!`: um cálculo de data que falha não vale derrubar a
    /// extensão inteira, então a queda é para daqui a quinze minutos em segundos.
    static var nextRefresh: Date {
        Calendar.current.date(byAdding: .minute, value: 15, to: Date())
            ?? Date().addingTimeInterval(15 * 60)
    }
}

// MARK: - Event Entry
struct EventEntry: TimelineEntry {
    let date: Date
    let event: Event?
    let isUserConfirmed: Bool
    let errorMessage: String?
    let configuration: ConfigurationAppIntent
}

// MARK: - Event Widget View
struct EventWidgetEntryView : View {
    var entry: EventProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                // Com dupla filiação há dois widgets iguais na tela. Sem o nome do
                // Capítulo escolhido, não há como saber qual é qual.
                Text(entry.configuration.chapter?.name ?? String(localized: "Próximo Evento"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                    .lineLimit(1)

                Spacer()

                if entry.errorMessage != nil && entry.event != nil {
                    StaleDataBadge()
                } else if family == .systemMedium, let event = entry.event {
                    Text(formatDate(event.scheduledDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let event = entry.event {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.body)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if family == .systemSmall {
                        Text(formatDate(event.scheduledDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if family == .systemMedium, let notes = event.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(intent: ConfirmAttendanceIntent(
                        eventId: event.id.uuidString,
                        membershipId: entry.configuration.chapter?.id.uuidString
                    )) {
                        HStack(spacing: 4) {
                            Image(systemName: entry.isUserConfirmed ? "checkmark.circle.fill" : "person.crop.circle.badge.plus")
                                .foregroundColor(entry.isUserConfirmed ? Color(UIColor.systemGreen) : .accent)
                                .font(family == .systemSmall ? .caption : .subheadline)
                            
                            Text(entry.isUserConfirmed ? family == .systemSmall ? "Confirmada" : "Presença confirmada" : family == .systemSmall ? "Confirmar" : "Confirmar presença")
                                .foregroundColor(Color(UIColor.label))
                                .font(family == .systemSmall ? .caption : .subheadline)
                                .bold()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            } else {
                // "Nenhum evento marcado" é mentira quando a busca falhou: o Capítulo
                // pode ter dez eventos e o widget não ter conseguido lê-los.
                WidgetPlaceholder(
                    icon: entry.errorMessage == nil ? "calendar.badge.checkmark" : "exclamationmark.triangle",
                    message: entry.errorMessage ?? String(localized: "Nenhum evento marcado"),
                    showsIcon: family == .systemMedium
                )
            }
        }
        .padding(2)
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }

    private func formatDate(_ date: Date) -> String {
        // Sem `Locale(identifier: "pt_BR")` fixo: a data seguia em português mesmo com
        // o aparelho em outro idioma.
        date.formatted(.dateTime.day().month(.twoDigits).hour().minute())
    }
}

/// Estado vazio e estado de falha usam a mesma forma de propósito: o que muda é o
/// ícone e a frase, e o widget é pequeno demais para dois desenhos diferentes.
struct WidgetPlaceholder: View {
    let icon: String
    let message: String
    let showsIcon: Bool

    var body: some View {
        HStack(spacing: 8) {
            if showsIcon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Quando há conteúdo em cache, a falha não pode tomar a tela — mas some sem aviso
/// nenhum era o que fazia o widget mostrar o evento da semana passada como se fosse o
/// próximo.
struct StaleDataBadge: View {
    var body: some View {
        Label(String(localized: "Sem conexão"), systemImage: "wifi.slash")
            .font(.caption2)
            .foregroundColor(.secondary)
            .accessibilityLabel(String(localized: "Mostrando dados salvos. Não foi possível atualizar."))
    }
}

// MARK: - Widget Configuration
struct EventWidget: Widget {
    let kind: String = "EventWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: EventProvider()) { entry in
            EventWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Próximo Evento")
        .description("Acompanhe o próximo evento e confirme sua presença.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Mock for Previews
extension Event {
    static var mock: Event {
        Event(id: UUID(), chapterId: UUID(), title: "Reunião Ritualística", scheduledDate: Date().addingTimeInterval(86400), eventType: "Ritualística", notes: "Apresentação de Trabalho", createdAt: Date())
    }
}

#Preview("Small", as: .systemSmall) {
    EventWidget()
} timeline: {
    EventEntry(date: .now, event: .mock, isUserConfirmed: false, errorMessage: nil, configuration: ConfigurationAppIntent())
}

#Preview("Medium", as: .systemMedium) {
    EventWidget()
} timeline: {
    EventEntry(date: .now, event: .mock, isUserConfirmed: true, errorMessage: nil, configuration: ConfigurationAppIntent())
}
