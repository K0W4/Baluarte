import EventKit
import Foundation

public final class EventKitManager {
    public static let shared = EventKitManager()
    
    private let eventStore = EKEventStore()
        
    public func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestWriteOnlyAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }
    
    public func addEventToCalendar(title: String, startDate: Date, endDate: Date, notes: String?) throws {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
    }
}
