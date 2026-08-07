import Foundation
@testable import App_DeMolay

public final class TestMockProfileService: ProfileServiceProtocol {
    public var shouldThrowError = false
    public var profileToReturn: UserProfile?

    public var fetchProfileCallCount = 0
    public var createProfileCallCount = 0
    public var updateProfileCallCount = 0
    public var updateActiveChapterCallCount = 0

    public init() {}

    public func fetchProfile(id: UUID) async throws -> UserProfile? {
        fetchProfileCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockProfileService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch profile"])
        }
        return profileToReturn
    }

    public func createProfile(_ profile: UserProfile) async throws {
        createProfileCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockProfileService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create profile"])
        }
    }

    public func updateProfile(_ profile: UserProfile) async throws {
        updateProfileCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockProfileService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to update profile"])
        }
    }

    public func updateActiveChapter(memberId: UUID, chapterId: UUID?) async throws {
        updateActiveChapterCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockProfileService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to update active chapter"])
        }
    }
}
