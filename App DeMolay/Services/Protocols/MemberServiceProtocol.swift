import Foundation

public protocol MemberServiceProtocol {
    func fetchMember(id: UUID) async throws -> Member?
    func fetchMembers(for chapterId: UUID) async throws -> [Member]
    func createMember(_ member: Member) async throws
    func updateMember(_ member: Member) async throws
    func deleteMember(memberId: UUID) async throws
}
