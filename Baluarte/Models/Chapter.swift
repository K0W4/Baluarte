import Foundation

public struct Chapter: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var number: Int
    public var uf: String?
    public var city: String?
    public var status: ChapterStatus
    public var hasOwner: Bool
    public var currentTermStart: Date?
    public var currentTermEnd: Date?
    public var createdAt: Date?

    public init(
        id: UUID,
        name: String,
        number: Int,
        uf: String? = nil,
        city: String? = nil,
        status: ChapterStatus = .active,
        hasOwner: Bool = false,
        currentTermStart: Date? = nil,
        currentTermEnd: Date? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.number = number
        self.uf = uf
        self.city = city
        self.status = status
        self.hasOwner = hasOwner
        self.currentTermStart = currentTermStart
        self.currentTermEnd = currentTermEnd
        self.createdAt = createdAt
    }

    /// "Porto Alegre · RS", or whichever half is known.
    public var locationLabel: String? {
        switch (city, uf) {
        case let (city?, uf?): return "\(city) · \(uf)"
        case let (city?, nil): return city
        case let (nil, uf?): return uf
        default: return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, number, uf, city, status
        case hasOwner = "has_owner"
        case currentTermStart = "current_term_start"
        case currentTermEnd = "current_term_end"
        case createdAt = "created_at"
    }
}
