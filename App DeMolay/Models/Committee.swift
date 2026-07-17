import Foundation

public struct Committee: Codable, Identifiable, Hashable {
    public let id: UUID
    public let chapterId: UUID
    public var name: String
    public var chairmanId: UUID?
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case name
        case chairmanId = "chairman_id"
        case createdAt = "created_at"
    }
}
