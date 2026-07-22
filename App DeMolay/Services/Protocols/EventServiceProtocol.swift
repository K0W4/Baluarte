import Foundation

public protocol EventServiceProtocol {
    func fetchEvents(for chapterId: UUID) async throws -> [Event]
    func createEvent(_ event: Event) async throws
    func confirmAttendance(eventId: UUID, userId: UUID) async throws
}
