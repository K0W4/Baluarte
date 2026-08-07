import Foundation

public protocol JoinRequestServiceProtocol {
    func createRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?) async throws -> JoinRequest
    func fetchMyPendingRequest(memberId: UUID) async throws -> JoinRequest?
    func fetchPendingRequests(for chapterId: UUID) async throws -> [PendingJoinRequest]
    func cancelRequest(id: UUID) async throws
    func approve(requestId: UUID, accessLevel: AccessLevel, category: MembershipCategory, role: String?) async throws
    func reject(requestId: UUID, reason: String?) async throws
}
