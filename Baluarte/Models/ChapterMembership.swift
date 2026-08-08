import Foundation

public struct ChapterMembership: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let chapterId: UUID
    public var memberId: UUID?
    public var fullName: String
    public var category: MembershipCategory
    public var role: String?
    public var cid: String?
    @SupabaseDate public var birthdate: Date?
    public var accessLevel: AccessLevel
    public var status: MembershipStatus
    public var joinedAt: Date?
    public var approvedBy: UUID?
    public var createdAt: Date

    public init(
        id: UUID,
        chapterId: UUID,
        memberId: UUID? = nil,
        fullName: String,
        category: MembershipCategory = .ativo,
        role: String? = nil,
        cid: String? = nil,
        birthdate: Date? = nil,
        accessLevel: AccessLevel = .member,
        status: MembershipStatus = .active,
        joinedAt: Date? = nil,
        approvedBy: UUID? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.chapterId = chapterId
        self.memberId = memberId
        self.fullName = fullName
        self.category = category
        self.role = role
        self.cid = cid
        self.birthdate = birthdate
        self.accessLevel = accessLevel
        self.status = status
        self.joinedAt = joinedAt
        self.approvedBy = approvedBy
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case memberId = "member_id"
        case fullName = "full_name"
        case category
        case role
        case cid
        case birthdate
        case accessLevel = "access_level"
        case status
        case joinedAt = "joined_at"
        case approvedBy = "approved_by"
        case createdAt = "created_at"
    }
}
