import Foundation

/// The chapter roster: everyone listed in a chapter, whether or not they have an account.
/// Backed by `chapter_roster`, a projection of `chapter_membership`.
public protocol MemberServiceProtocol {
    func fetchMembers(for chapterId: UUID) async throws -> [Member]
    func createMember(_ member: Member) async throws
    func updateMember(_ member: Member) async throws
    func deleteMember(memberId: UUID) async throws
}
