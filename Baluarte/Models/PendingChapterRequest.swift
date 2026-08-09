import Foundation

/// Projeção da RPC `pending_chapter_requests`. Não é `ChapterRequest` — aquele é a
/// linha como quem pediu a vê; este é o que quem revisa precisa, com o nome de quem
/// pediu já resolvido, para a tela não ter de ler a tabela de pessoas.
nonisolated public struct PendingChapterRequest: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let number: Int
    public let uf: String
    public let city: String?
    public let note: String?
    public let createdAt: Date
    public let requesterName: String

    enum CodingKeys: String, CodingKey {
        case id, name, number, uf, city, note
        case createdAt = "created_at"
        case requesterName = "requester_name"
    }

    public var location: String {
        guard let city, !city.isEmpty else { return uf }
        return "\(city) · \(uf)"
    }
}
