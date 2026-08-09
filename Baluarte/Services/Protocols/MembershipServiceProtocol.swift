import Foundation

/// The signed-in person's own bonds with chapters. There is no `join` here on purpose:
/// entering a chapter goes through `JoinRequestServiceProtocol` and someone's approval.
public protocol MembershipServiceProtocol {
    func fetchMemberships(for memberId: UUID) async throws -> [ChapterMembership]
    func leaveChapter(chapterId: UUID) async throws
    func setAccessLevel(membershipId: UUID, level: AccessLevel) async throws
    func transferOwnership(toMembershipId: UUID) async throws

    /// Cadeia de confiança: só quem já é administrador de plataforma concede a
    /// outro. A recusa é do servidor -- aqui só desenhamos a tela.
    func platformAdmins() async throws -> [PlatformAdmin]
    /// Concede por CID e não por id: a resolução acontece no servidor justamente
    /// para não existir um endpoint que devolva pessoas.
    func grantPlatformAdmin(cid: String) async throws
    func revokePlatformAdmin(memberId: UUID) async throws
}
