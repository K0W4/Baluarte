import Foundation

public struct ChapterTask: Codable, Identifiable, Hashable {
    public let id: UUID
    public let chapterId: UUID
    public let creatorId: UUID
    public var assigneeId: UUID?
    public var committeeId: UUID?
    public var title: String
    public var description: String
    public var isCompleted: Bool
    public var dueDate: Date?
    public var createdAt: Date
    
    public init(id: UUID, chapterId: UUID, creatorId: UUID, assigneeId: UUID? = nil, committeeId: UUID? = nil, title: String, description: String, isCompleted: Bool, dueDate: Date? = nil, createdAt: Date) {
        self.id = id
        self.chapterId = chapterId
        self.creatorId = creatorId
        self.assigneeId = assigneeId
        self.committeeId = committeeId
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case creatorId = "creator_id"
        case assigneeId = "assignee_id"
        case committeeId = "committee_id"
        case title
        case description
        case isCompleted = "is_completed"
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}
