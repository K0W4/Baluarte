import Foundation
import Supabase
import WidgetKit

public final class SupabaseEventService: BaseSupabaseService<Event>, EventServiceProtocol {
    
    public init() {
        super.init(tableName: "event")
    }
    
    public func fetchEvents(for chapterId: UUID) async throws -> [Event] {
        try await fetchAll(chapterId: chapterId)
    }
    
    public func createEvent(_ event: Event) async throws {
        try await create(event)
    }
    
    public func updateEvent(_ event: Event) async throws {
        try await update(event)
    }
    
    public func deleteEvent(eventId: UUID) async throws {
        try await delete(id: eventId)
    }
    
    public func confirmAttendance(eventId: UUID, userId: UUID) async throws {
        let event: Event = try await client
            .from("event")
            .select()
            .eq("id", value: eventId)
            .single()
            .execute()
            .value
        
        var attendees = event.confirmedAttendees ?? []
        if !attendees.contains(userId) {
            attendees.append(userId)
            
            struct UpdateAttendees: Codable {
                let confirmed_attendees: [UUID]
            }
            
            try await client
                .from("event")
                .update(UpdateAttendees(confirmed_attendees: attendees))
                .eq("id", value: eventId)
                .execute()
            WidgetManager.shared.reloadTimelines()
        }
    }
    
    public func removeAttendance(eventId: UUID, userId: UUID) async throws {
        let event: Event = try await client
            .from("event")
            .select()
            .eq("id", value: eventId)
            .single()
            .execute()
            .value
        
        var attendees = event.confirmedAttendees ?? []
        if attendees.contains(userId) {
            attendees.removeAll { $0 == userId }
            
            struct UpdateAttendees: Codable {
                let confirmed_attendees: [UUID]
            }
            
            try await client
                .from("event")
                .update(UpdateAttendees(confirmed_attendees: attendees))
                .eq("id", value: eventId)
                .execute()
            WidgetManager.shared.reloadTimelines()
        }
    }
}
