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
