import Foundation

/// The signed-in person's own bonds with chapters. There is no `join` here on purpose:
/// entering a chapter goes through `JoinRequestServiceProtocol` and someone's approval.
public protocol MembershipServiceProtocol {
    func fetchMemberships(for memberId: UUID) async throws -> [ChapterMembership]
    func leaveChapter(chapterId: UUID) async throws
    func setAccessLevel(membershipId: UUID, level: AccessLevel) async throws
    func transferOwnership(toMembershipId: UUID) async throws
}
