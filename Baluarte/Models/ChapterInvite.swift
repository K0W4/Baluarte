import Foundation

public struct ChapterInvite: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let chapterId: UUID
    public let code: String
    public var targetMembershipId: UUID?
    public var expiresAt: Date?
    public var maxUses: Int?
    public var usesCount: Int
    public var revokedAt: Date?
    public var createdBy: UUID
    public var createdAt: Date

    public init(
        id: UUID,
        chapterId: UUID,
        code: String,
        targetMembershipId: UUID? = nil,
        expiresAt: Date? = nil,
        maxUses: Int? = nil,
        usesCount: Int = 0,
        revokedAt: Date? = nil,
        createdBy: UUID,
        createdAt: Date
    ) {
        self.id = id
        self.chapterId = chapterId
        self.code = code
        self.targetMembershipId = targetMembershipId
        self.expiresAt = expiresAt
        self.maxUses = maxUses
        self.usesCount = usesCount
        self.revokedAt = revokedAt
        self.createdBy = createdBy
        self.createdAt = createdAt
    }

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    public var isExhausted: Bool {
        guard let maxUses else { return false }
        return usesCount >= maxUses
    }

    public var isRevoked: Bool { revokedAt != nil }

    public var isUsable: Bool { !isRevoked && !isExpired && !isExhausted }

    /// Stored without a separator; the dash is presentation only.
    public var formattedCode: String {
        InviteCode.format(code)
    }

    enum CodingKeys: String, CodingKey {
        case id, code
        case chapterId = "chapter_id"
        case targetMembershipId = "target_membership_id"
        case expiresAt = "expires_at"
        case maxUses = "max_uses"
        case usesCount = "uses_count"
        case revokedAt = "revoked_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

/// One place that knows what a code looks like, so the entry field, the share sheet and
/// the deep link cannot drift apart.
public enum InviteCode {
    public static let length = 8

    /// No I, L, O, U, 0 or 1 — nobody dictates those correctly out loud.
    public static let alphabet = "23456789ABCDEFGHJKMNPQRSTVWXYZ"

    /// Uppercase, separators stripped. This is what the server compares against.
    public static func normalize(_ raw: String) -> String {
        String(raw.uppercased().filter { alphabet.contains($0) })
    }

    /// "4K7QX2MN" → "4K7Q-X2MN"
    public static func format(_ raw: String) -> String {
        let normalized = normalize(raw)
        guard normalized.count > 4 else { return normalized }
        let split = normalized.index(normalized.startIndex, offsetBy: 4)
        return "\(normalized[..<split])-\(normalized[split...])"
    }

    public static func isComplete(_ raw: String) -> Bool {
        normalize(raw).count == length
    }
}
