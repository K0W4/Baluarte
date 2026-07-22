import Foundation
import Observation

@Observable
public final class CalendarViewModel {
    public var events: [Event] = []
    public var selectedDate: Date = Date()
    public var currentMonth: Date = Date()
    
    public var isLoading = false
    public var errorMessage: String?
    
    private let eventService: EventServiceProtocol
    private let currentUserId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    
    public init(eventService: EventServiceProtocol = MockEventService()) {
        self.eventService = eventService
    }
    
    @MainActor
    public func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let mockChapterId = UUID()
            events = try await eventService.fetchEvents(for: mockChapterId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func events(for date: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
    }
    
    public func hasEvents(for date: Date) -> Bool {
        !events(for: date).isEmpty
    }
    
    public func confirmAttendance(eventId: UUID) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            var attendees = events[index].confirmedAttendees ?? []
            if attendees.contains(currentUserId) {
                attendees.removeAll { $0 == currentUserId }
            } else {
                attendees.append(currentUserId)
            }
            events[index].confirmedAttendees = attendees
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
            print("Erro ao adicionar evento: \(error)")
        }
    }
}
