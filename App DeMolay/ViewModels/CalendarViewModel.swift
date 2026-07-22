import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class CalendarViewModel {
    public var events: [Event] = []
    public var selectedDate: Date = Date()
    public var currentMonth: Date = Date()

    public var isLoading = false
    public var errorMessage: String?

    private let eventService: EventServiceProtocol
    private let currentUserId = UUID()

    public init(eventService: EventServiceProtocol = MockEventService()) {
        self.eventService = eventService
    }

    public func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let mockChapterId = UUID()
            events = try await eventService.fetchEvents(for: mockChapterId)
        } catch {
            errorMessage = error.localizedDescription
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }

    public func events(for date: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    public func hasEvents(for date: Date) -> Bool {
        !events(for: date).isEmpty
    }

    public func confirmAttendance(eventId: UUID) async {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        let originalAttendees = events[index].confirmedAttendees

        var attendees = events[index].confirmedAttendees ?? []
        if attendees.contains(currentUserId) {
            attendees.removeAll { $0 == currentUserId }
            HapticManager.shared.impact(style: .rigid)
        } else {
            attendees.append(currentUserId)
            HapticManager.shared.impact(style: .medium)
        }
        events[index].confirmedAttendees = attendees

        do {
            try await eventService.confirmAttendance(eventId: eventId, userId: currentUserId)
        } catch {
            events[index].confirmedAttendees = originalAttendees
        }
    }

    public func addToNativeCalendar(event: Event) async {
        do {
            let granted = try await EventKitManager.shared.requestAccess()
            if granted {
                let endDate = event.scheduledDate.addingTimeInterval(2 * 3600)
                try EventKitManager.shared.addEventToCalendar(
                    title: event.title,
                    startDate: event.scheduledDate,
                    endDate: endDate,
                    notes: event.notes
                )
            }
        } catch {
            errorMessage = "Não foi possível adicionar ao calendário."
        }
    }
}
