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

    public var setAccessLevelCallCount = 0
    public var transferOwnershipCallCount = 0
    public private(set) var lastAccessLevel: AccessLevel?

    public func setAccessLevel(membershipId: UUID, level: AccessLevel) async throws {
        setAccessLevelCallCount += 1
        lastAccessLevel = level
        if shouldThrowError {
            throw NSError(domain: "TestMockMembershipService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to set access level"])
        }
    }

    public func transferOwnership(toMembershipId: UUID) async throws {
        transferOwnershipCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMembershipService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to transfer ownership"])
        }
    }

    public func leaveChapter(chapterId: UUID) async throws {
        leaveChapterCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMembershipService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to leave chapter"])
        }
    }
}
