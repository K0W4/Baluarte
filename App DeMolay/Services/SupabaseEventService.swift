import Foundation
import Supabase
import WidgetKit

public final class SupabaseEventService: EventServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    public init() {}
    
    public func fetchEvents(for chapterId: UUID) async throws -> [Event] {
        let response: [Event] = try await client
            .from("event")
            .select()
            .eq("chapter_id", value: chapterId)
            .execute()
            .value
        
        return response
    }
    
    public func createEvent(_ event: Event) async throws {
        try await client
            .from("event")
            .insert(event)
            .execute()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func updateEvent(_ event: Event) async throws {
        try await client
            .from("event")
            .update(event)
            .eq("id", value: event.id)
            .execute()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func deleteEvent(eventId: UUID) async throws {
        try await client
            .from("event")
            .delete()
            .eq("id", value: eventId)
            .execute()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func confirmAttendance(eventId: UUID, userId: UUID) async throws {
        // Fetch current event to update the array
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
            WidgetCenter.shared.reloadAllTimelines()
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
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
