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
        var nextEvent: Event? = nil
        var fetchError: String? = nil
        var isConfirmed = false
        do {
            let events = try await WidgetDataManager.shared.fetchUpcomingEvents()
            nextEvent = events.first
            if let attendees = nextEvent?.confirmedAttendees,
               let membershipIdString = UserDefaults(suiteName: "group.com.kowa.baluarte")?.string(forKey: "currentMembershipId"),
               let membershipUUID = UUID(uuidString: membershipIdString) {
                isConfirmed = attendees.contains(membershipUUID)
            }
        } catch {
            fetchError = error.localizedDescription
            print("Widget Error: \(error)")

            nextEvent = WidgetDataManager.shared.cachedEvents()?.first
            if let attendees = nextEvent?.confirmedAttendees,
               let membershipIdString = UserDefaults(suiteName: "group.com.kowa.baluarte")?.string(forKey: "currentMembershipId"),
               let membershipUUID = UUID(uuidString: membershipIdString) {
                isConfirmed = attendees.contains(membershipUUID)
            }
        }

        let entry = EventEntry(date: Date(), event: nextEvent, isUserConfirmed: isConfirmed, errorMessage: fetchError, configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
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
                Text("Próximo Evento")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                
                Spacer()
                
                if family == .systemMedium, let event = entry.event {
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
                    Button(intent: ConfirmAttendanceIntent(eventId: event.id.uuidString)) {
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
                HStack(spacing: 8) {
                    if family == .systemMedium {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Nenhum evento marcado")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(2)
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM 'às' HH:mm"
        return formatter.string(from: date)
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
