import Foundation

/// The signed-in person, one row per `auth.users` entry.
public protocol ProfileServiceProtocol {
    func fetchProfile(id: UUID) async throws -> UserProfile?
    func createProfile(_ profile: UserProfile) async throws
    func updateProfile(_ profile: UserProfile) async throws
    func updateActiveChapter(memberId: UUID, chapterId: UUID?) async throws
}
