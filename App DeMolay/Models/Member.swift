import Foundation

public struct Member: Codable, Identifiable, Hashable {
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
    }
}
