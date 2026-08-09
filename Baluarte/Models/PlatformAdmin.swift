import Foundation

/// Projeção da RPC `platform_admins` — só o que a tela de plataforma precisa para
/// listar pares. Não é a pessoa (`UserProfile`) nem o vínculo (`ChapterMembership`):
/// administrador de plataforma existe fora de qualquer Capítulo.
public struct PlatformAdmin: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let fullName: String
    public let email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
    }
}
