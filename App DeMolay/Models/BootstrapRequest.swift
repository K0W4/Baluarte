import Foundation

/// Uma solicitação para fundar um Capítulo sem dono, já com o nome de quem pediu e os
/// dados do Capítulo — é o que a revisão precisa ver, e não um punhado de UUIDs.
public struct BootstrapRequest: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let chapterId: UUID
    public let memberId: UUID
    public var message: String?
    public var cidSnapshot: String?
    public var proofPath: String?
    public var createdAt: Date
    public var applicantName: String
    public var chapterName: String
    public var chapterNumber: Int
    public var chapterUf: String?

    public var chapterLabel: String {
        var label = "\(chapterName) nº \(chapterNumber)"
        if let chapterUf { label += " · \(chapterUf)" }
        return label
    }

    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case memberId = "member_id"
        case message
        case cidSnapshot = "cid_snapshot"
        case proofPath = "proof_path"
        case createdAt = "created_at"
        case applicantName = "applicant_name"
        case chapterName = "chapter_name"
        case chapterNumber = "chapter_number"
        case chapterUf = "chapter_uf"
    }
}
