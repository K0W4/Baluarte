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
    public var currentUserId: UUID?
    public var currentChapterId: UUID?

    public init(eventService: EventServiceProtocol = Services.event) {
        self.eventService = eventService
    }

    public func loadEvents(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil
        do {
            if let chapterId = currentChapterId {
                events = try await eventService.fetchEvents(for: chapterId)
            }
        } catch {
            if error is CancellationError { 
                withAnimation(.easeInOut(duration: 0.3)) { self.isLoading = false }
                return 
            }
            errorMessage = AppError.from(error).userMessage
        }
        if showLoading {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }

    public func events(for date: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    public func hasEvents(for date: Date) -> Bool {
        !events(for: date).isEmpty
    }

    public func isUserConfirmed(for event: Event) -> Bool {
        guard let userId = currentUserId else { return false }
        return event.confirmedAttendees?.contains(userId) ?? false
    }

    public func confirmAttendance(eventId: UUID) async {
        guard let index = events.firstIndex(where: { $0.id == eventId }), let userId = currentUserId else { return }
        let originalAttendees = events[index].confirmedAttendees

        var attendees = events[index].confirmedAttendees ?? []
        let isRemoving = attendees.contains(userId)
        if isRemoving {
            attendees.removeAll { $0 == userId }
            HapticManager.shared.impact(style: .rigid)
        } else {
            attendees.append(userId)
            HapticManager.shared.impact(style: .medium)
        }
        events[index].confirmedAttendees = attendees

        do {
            if isRemoving {
                try await eventService.removeAttendance(eventId: eventId, userId: userId)
            } else {
                try await eventService.confirmAttendance(eventId: eventId, userId: userId)
            }
        } catch {
            if error is CancellationError { return }
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
            if error is CancellationError { return }
            errorMessage = "Não foi possível adicionar ao calendário."
        }
    }
}
