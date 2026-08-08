import Foundation

public protocol InviteServiceProtocol {
    func fetchInvites(for chapterId: UUID) async throws -> [ChapterInvite]
    func createInvite(chapterId: UUID, createdBy: UUID, expiresAt: Date?, maxUses: Int?) async throws -> ChapterInvite
    func revokeInvite(id: UUID) async throws
    func redeem(code: String) async throws -> ChapterMembership
}
