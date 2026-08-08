import Foundation

public protocol EventServiceProtocol {
    func fetchEvents(for chapterId: UUID) async throws -> [Event]
    func createEvent(_ event: Event) async throws
    func updateEvent(_ event: Event) async throws
    func deleteEvent(eventId: UUID) async throws
    func confirmAttendance(eventId: UUID, userId: UUID) async throws
    func removeAttendance(eventId: UUID, userId: UUID) async throws
}
