import Foundation

public struct Goal: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let chapterId: UUID
    public var title: String
    public var description: String?
    public var currentValue: Double
    public var targetValue: Double
    public var targetDate: Date?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var createdAt: Date
    
    public var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return currentValue / targetValue
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case title, description
        case currentValue = "current_value"
        case targetValue = "target_value"
        case targetDate = "target_date"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
}
