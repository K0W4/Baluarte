import Foundation

public protocol JoinRequestServiceProtocol {
    func createRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?) async throws -> JoinRequest
    func fetchMyPendingRequest(memberId: UUID) async throws -> JoinRequest?
    func fetchPendingRequests(for chapterId: UUID) async throws -> [PendingJoinRequest]
    func cancelRequest(id: UUID) async throws
    func approve(requestId: UUID, accessLevel: AccessLevel, category: MembershipCategory, role: String?) async throws
    func reject(requestId: UUID, reason: String?) async throws

    // MARK: - Bootstrap (Capítulo sem Fundador)

    func uploadProof(memberId: UUID, imageData: Data) async throws -> String
    func createBootstrapRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?, proofPath: String) async throws -> JoinRequest
    func fetchPendingBootstrapRequests() async throws -> [BootstrapRequest]
    func signedProofURL(path: String) async throws -> URL
}
