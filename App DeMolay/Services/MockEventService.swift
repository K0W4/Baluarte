import Foundation

public struct MockEventService: EventServiceProtocol {
    public init() {}
    
    public func fetchEvents(for chapterId: UUID) async throws -> [Event] {
        return [
            Event(id: UUID(), chapterId: chapterId, title: "Reunião Ritualística", scheduledDate: Date().addingTimeInterval(86400 * 2), eventType: "Ritual", notes: "Traje completo", createdAt: Date()),
            Event(id: UUID(), chapterId: chapterId, title: "Filantropia: Arrecadação", scheduledDate: Date().addingTimeInterval(86400 * 5), eventType: "Filantropia", notes: "Levar caixas", createdAt: Date())
        ]
    }
    
    public func createEvent(_ event: Event) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
