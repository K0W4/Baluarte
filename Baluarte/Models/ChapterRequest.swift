import Foundation

public struct ChapterRequest: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var requestedBy: UUID
    public var name: String
    public var number: Int
    public var uf: String
    public var city: String?
    public var note: String?
    public var status: String
    public var createdAt: Date?

    public init(
        id: UUID = UUID(),
        requestedBy: UUID,
        name: String,
        number: Int,
        uf: String,
        city: String? = nil,
        note: String? = nil,
        status: String = "pending",
        createdAt: Date? = nil
    ) {
        self.id = id
        self.requestedBy = requestedBy
        self.name = name
        self.number = number
        self.uf = uf
        self.city = city
        self.note = note
        self.status = status
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case requestedBy = "requested_by"
        case name, number, uf, city, note, status
        case createdAt = "created_at"
    }
}
