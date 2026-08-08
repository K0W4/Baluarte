import Foundation
@testable import Baluarte

public final class TestMockInviteService: InviteServiceProtocol {
    public var shouldThrowError = false
    public var invitesToReturn: [ChapterInvite] = []

    public var fetchInvitesCallCount = 0
    public var createInviteCallCount = 0
    public var revokeInviteCallCount = 0
    public var redeemCallCount = 0

    public private(set) var lastCreatedExpiry: Date?
    public private(set) var lastCreatedMaxUses: Int?
    public private(set) var lastRedeemedCode: String?

    public init() {}

    public func fetchInvites(for chapterId: UUID) async throws -> [ChapterInvite] {
        fetchInvitesCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockInviteService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch invites"])
        }
        return invitesToReturn
    }

    public func createInvite(chapterId: UUID, createdBy: UUID, expiresAt: Date?, maxUses: Int?) async throws -> ChapterInvite {
        createInviteCallCount += 1
        lastCreatedExpiry = expiresAt
        lastCreatedMaxUses = maxUses
        if shouldThrowError {
            throw NSError(domain: "TestMockInviteService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create invite"])
        }
        return ChapterInvite(
            id: UUID(),
            chapterId: chapterId,
            code: "4K7QX2MN",
            expiresAt: expiresAt,
            maxUses: maxUses,
            createdBy: createdBy,
            createdAt: Date()
        )
    }

    public func revokeInvite(id: UUID) async throws {
        revokeInviteCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockInviteService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to revoke invite"])
        }
    }

    public func redeem(code: String) async throws -> ChapterMembership {
        redeemCallCount += 1
        lastRedeemedCode = code
        if shouldThrowError {
            throw NSError(domain: "TestMockInviteService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to redeem invite"])
        }
        return ChapterMembership(id: UUID(), chapterId: UUID(), memberId: UUID(), fullName: "Membro", createdAt: Date())
    }
}
