import Foundation
@testable import App_DeMolay

public final class TestMockMembershipService: MembershipServiceProtocol {
    public var shouldThrowError = false
    public var membershipsToReturn: [ChapterMembership] = []

    public var fetchMembershipsCallCount = 0
    public var leaveChapterCallCount = 0

    public init() {}

    public func fetchMemberships(for memberId: UUID) async throws -> [ChapterMembership] {
        fetchMembershipsCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMembershipService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch memberships"])
        }
        return membershipsToReturn
    }

    public func leaveChapter(chapterId: UUID) async throws {
        leaveChapterCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMembershipService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to leave chapter"])
        }
    }
}
