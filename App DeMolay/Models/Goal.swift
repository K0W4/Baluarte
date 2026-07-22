import Foundation

public struct Goal: Codable, Identifiable, Hashable {
    public let id: UUID
    public let chapterId: UUID
    public var type: String
    public var title: String
    public var description: String?
    public var currentValue: Double
    public var targetValue: Double
    public var targetDate: Date?
    public var createdAt: Date
    
    public var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return currentValue / targetValue
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case type, title, description
        case currentValue = "current_value"
        case targetValue = "target_value"
        case targetDate = "target_date"
        case createdAt = "created_at"
    }
}
