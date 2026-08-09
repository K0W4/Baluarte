import Foundation

public enum JoinRequestKind: String, Codable, Hashable, Sendable {
    case chapterJoin = "chapter_join"
    case chapterBootstrap = "chapter_bootstrap"
}

public enum JoinRequestStatus: String, Codable, Hashable, Sendable {
    case pending
    case approved
    case rejected
    case cancelled
}

public struct JoinRequest: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let chapterId: UUID
    public let memberId: UUID
    public var kind: JoinRequestKind
    public var status: JoinRequestStatus
    public var message: String?
    public var cidSnapshot: String?
    public var createdAt: Date
    public var rejectReason: String?

    public init(
        id: UUID,
        chapterId: UUID,
        memberId: UUID,
        kind: JoinRequestKind = .chapterJoin,
        status: JoinRequestStatus = .pending,
        message: String? = nil,
        cidSnapshot: String? = nil,
        createdAt: Date,
        rejectReason: String? = nil
    ) {
        self.id = id
        self.chapterId = chapterId
        self.memberId = memberId
        self.kind = kind
        self.status = status
        self.message = message
        self.cidSnapshot = cidSnapshot
        self.createdAt = createdAt
        self.rejectReason = rejectReason
    }

    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case memberId = "member_id"
        case kind, status, message
        case cidSnapshot = "cid_snapshot"
        case createdAt = "created_at"
        case rejectReason = "reject_reason"
    }
}

/// A pending request joined with the applicant's profile, which is what an admin needs
/// to decide: a name and a CID, not a UUID.
public struct PendingJoinRequest: Identifiable, Hashable, Sendable {
    public let request: JoinRequest
    public let applicantName: String

    public var id: UUID { request.id }
}
