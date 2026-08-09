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
    
    private struct SetAttendanceParams: Encodable {
        let p_event_id: UUID
        let p_confirmed: Bool
    }

    /// Attendance is written server-side: an UPDATE policy cannot inspect an array
    /// delta, so it could not stop one member confirming on another's behalf. The
    /// RPC also removes the read-modify-write race this method used to have.
    /// `userId` is ignored — the server derives the membership from the caller's JWT.
    private func setAttendance(eventId: UUID, confirmed: Bool) async throws {
        try await client
            .rpc("set_event_attendance", params: SetAttendanceParams(
                p_event_id: eventId,
                p_confirmed: confirmed
            ))
            .execute()
        WidgetManager.shared.reloadTimelines()
    }

    public func confirmAttendance(eventId: UUID, userId: UUID) async throws {
        try await setAttendance(eventId: eventId, confirmed: true)
    }

    public func removeAttendance(eventId: UUID, userId: UUID) async throws {
        try await setAttendance(eventId: eventId, confirmed: false)
    }
}
