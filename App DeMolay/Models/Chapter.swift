import Foundation

public struct Chapter: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var number: Int
    public var currentTermStart: Date?
    public var currentTermEnd: Date?
    public var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, number
        case currentTermStart = "current_term_start"
        case currentTermEnd = "current_term_end"
        case createdAt = "created_at"
    }
}
