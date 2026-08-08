import Foundation

public struct Member: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var chapterId: UUID?
    public var fullName: String
    public var role: String?
    public var isActive: Bool
    public var isSenior: Bool
    public var isMason: Bool
    public var accessLevel: String
    @SupabaseDate public var birthdate: Date?
    public var cid: String?
    public var createdAt: Date
    /// False for a roster entry an admin typed in before that person had an account.
    /// Only those can be deleted — a real person's bond is ended by leaving, not erased.
    public var hasAccount: Bool = false

    public var level: AccessLevel { AccessLevel(rawValueOrMember: accessLevel) }

    public init(
        id: UUID,
        chapterId: UUID? = nil,
        fullName: String,
        role: String? = nil,
        isActive: Bool,
        isSenior: Bool,
        isMason: Bool,
        accessLevel: String,
        birthdate: Date? = nil,
        cid: String? = nil,
        createdAt: Date,
        hasAccount: Bool = false
    ) {
        self.id = id
        self.chapterId = chapterId
        self.fullName = fullName
        self.role = role
        self.isActive = isActive
        self.isSenior = isSenior
        self.isMason = isMason
        self.accessLevel = accessLevel
        self.birthdate = birthdate
        self.cid = cid
        self.createdAt = createdAt
        self.hasAccount = hasAccount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case fullName = "full_name"
        case role
        case isActive = "is_active"
        case isSenior = "is_senior"
        case isMason = "is_mason"
        case accessLevel = "access_level"
        case birthdate
        case cid
        case createdAt = "created_at"
        case hasAccount = "has_account"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        chapterId = try container.decodeIfPresent(UUID.self, forKey: .chapterId)
        fullName = try container.decode(String.self, forKey: .fullName)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isSenior = try container.decode(Bool.self, forKey: .isSenior)
        isMason = try container.decode(Bool.self, forKey: .isMason)
        accessLevel = try container.decode(String.self, forKey: .accessLevel)
        _birthdate = try container.decode(SupabaseDate.self, forKey: .birthdate)
        cid = try container.decodeIfPresent(String.self, forKey: .cid)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        hasAccount = try container.decodeIfPresent(Bool.self, forKey: .hasAccount) ?? false
    }
}
