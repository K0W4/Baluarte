import Foundation

public struct Event: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let chapterId: UUID
    public var title: String
    public var scheduledDate: Date
    public var eventType: String
    public var notes: String?
    public var confirmedAttendees: [UUID]?
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case title
        case scheduledDate = "scheduled_date"
        case eventType = "event_type"
        case notes
        case confirmedAttendees = "confirmed_attendees"
        case createdAt = "created_at"
    }
}
