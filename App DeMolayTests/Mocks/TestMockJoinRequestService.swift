import Foundation
@testable import App_DeMolay

public final class TestMockJoinRequestService: JoinRequestServiceProtocol {
    public var shouldThrowError = false
    public var pendingToReturn: [PendingJoinRequest] = []
    public var myRequestToReturn: JoinRequest?

    public var createRequestCallCount = 0
    public var fetchMyPendingRequestCallCount = 0
    public var fetchPendingRequestsCallCount = 0
    public var cancelRequestCallCount = 0
    public var approveCallCount = 0
    public var rejectCallCount = 0

    public private(set) var lastApprovedAccessLevel: AccessLevel?
    public private(set) var lastApprovedRole: String?
    public private(set) var lastLinkedMembershipId: UUID?

    public init() {}

    public func createRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?) async throws -> JoinRequest {
        createRequestCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create request"])
        }
        return JoinRequest(id: UUID(), chapterId: chapterId, memberId: memberId, message: message, createdAt: Date())
    }

    public func fetchMyPendingRequest(memberId: UUID) async throws -> JoinRequest? {
        fetchMyPendingRequestCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch request"])
        }
        return myRequestToReturn
    }

    public func fetchPendingRequests(for chapterId: UUID) async throws -> [PendingJoinRequest] {
        fetchPendingRequestsCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch pending requests"])
        }
        return pendingToReturn
    }

    public func cancelRequest(id: UUID) async throws {
        cancelRequestCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to cancel request"])
        }
    }

    public func approve(requestId: UUID, accessLevel: AccessLevel, category: MembershipCategory, role: String?, linkMembershipId: UUID?) async throws {
        approveCallCount += 1
        lastApprovedAccessLevel = accessLevel
        lastApprovedRole = role
        lastLinkedMembershipId = linkMembershipId
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to approve"])
        }
    }

    public func reject(requestId: UUID, reason: String?) async throws {
        rejectCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to reject"])
        }
    }

    // MARK: - Bootstrap

    public var bootstrapToReturn: [BootstrapRequest] = []

    public var uploadProofCallCount = 0
    public var createBootstrapRequestCallCount = 0
    public var fetchPendingBootstrapRequestsCallCount = 0
    public var signedProofURLCallCount = 0

    public private(set) var lastUploadedByteCount: Int?
    public private(set) var lastBootstrapProofPath: String?

    public func uploadProof(memberId: UUID, imageData: Data) async throws -> String {
        uploadProofCallCount += 1
        lastUploadedByteCount = imageData.count
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to upload proof"])
        }
        return "\(memberId.uuidString)/\(UUID().uuidString).jpg"
    }

    public func createBootstrapRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?, proofPath: String) async throws -> JoinRequest {
        createBootstrapRequestCallCount += 1
        lastBootstrapProofPath = proofPath
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to create bootstrap request"])
        }
        return JoinRequest(
            id: UUID(),
            chapterId: chapterId,
            memberId: memberId,
            kind: .chapterBootstrap,
            message: message,
            createdAt: Date()
        )
    }

    public func fetchPendingBootstrapRequests() async throws -> [BootstrapRequest] {
        fetchPendingBootstrapRequestsCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 9, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch bootstrap requests"])
        }
        return bootstrapToReturn
    }

    public func signedProofURL(path: String) async throws -> URL {
        signedProofURLCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockJoinRequestService", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to sign proof URL"])
        }
        guard let url = URL(string: "https://example.test/\(path)") else {
            throw NSError(domain: "TestMockJoinRequestService", code: 11, userInfo: [NSLocalizedDescriptionKey: "Bad path"])
        }
        return url
    }
}
