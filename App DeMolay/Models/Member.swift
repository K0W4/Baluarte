import Foundation

public struct Member: Codable, Identifiable, Hashable {
    public let id: UUID
    public let chapterId: UUID
    public var fullName: String
    public var role: String?
    public var isActive: Bool
    public var cid: String?
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case fullName = "full_name"
        case role
        case isActive = "is_active"
        case cid
        case createdAt = "created_at"
    }
}
