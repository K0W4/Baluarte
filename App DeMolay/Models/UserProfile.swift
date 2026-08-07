import Foundation

public struct UserProfile: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var fullName: String
    public var cid: String?
    @SupabaseDate public var birthdate: Date?
    public var activeChapterId: UUID?
    public var isPlatformAdmin: Bool
    public var createdAt: Date

    public init(
        id: UUID,
        fullName: String,
        cid: String? = nil,
        birthdate: Date? = nil,
        activeChapterId: UUID? = nil,
        isPlatformAdmin: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.fullName = fullName
        self.cid = cid
        self.birthdate = birthdate
        self.activeChapterId = activeChapterId
        self.isPlatformAdmin = isPlatformAdmin
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case cid
        case birthdate
        case activeChapterId = "active_chapter_id"
        case isPlatformAdmin = "is_platform_admin"
        case createdAt = "created_at"
    }
}
