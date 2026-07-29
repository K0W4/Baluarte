import Foundation
@testable import App_DeMolay

public final class TestMockEventService: EventServiceProtocol {
    public var shouldThrowError = false
    public var eventsToReturn: [Event] = []
    
    public var fetchEventsCallCount = 0
    public var createEventCallCount = 0
    public var confirmAttendanceCallCount = 0
    public var removeAttendanceCallCount = 0
    public var updateEventCallCount = 0
    public var deleteEventCallCount = 0
    
    public init() {}
    
    public func fetchEvents(for chapterId: UUID) async throws -> [Event] {
        fetchEventsCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockEventService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch events"])
        }
        return eventsToReturn
    }
    
    public func createEvent(_ event: Event) async throws {
        createEventCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockEventService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"])
        }
    }

    public func confirmAttendance(eventId: UUID, userId: UUID) async throws {
        confirmAttendanceCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockEventService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to confirm attendance"])
        }
    }

    public func removeAttendance(eventId: UUID, userId: UUID) async throws {
        removeAttendanceCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockEventService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to remove attendance"])
        }
    }
    
    public func updateEvent(_ event: Event) async throws {
        updateEventCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockEventService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to update event"])
        }
    }
    
    public func deleteEvent(eventId: UUID) async throws {
        deleteEventCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockEventService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to delete event"])
        }
    }
}
