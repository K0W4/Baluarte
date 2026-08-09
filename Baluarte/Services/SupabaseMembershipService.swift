import Foundation
import Supabase

public final class SupabaseMembershipService: MembershipServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    public init() {}

    private struct LeaveParams: Encodable {
        let p_chapter_id: UUID
    }

    private struct AccessLevelParams: Encodable {
        let p_membership_id: UUID
        let p_access_level: String
    }

    private struct GrantPlatformParams: Encodable {
        let p_cid: String
    }

    private struct PlatformAdminParams: Encodable {
        let p_member_id: UUID
        let p_is_admin: Bool
    }

    private struct TransferParams: Encodable {
        let p_to_membership_id: UUID
    }

    public func fetchMemberships(for memberId: UUID) async throws -> [ChapterMembership] {
        try await client
            .from("chapter_membership")
            .select()
            .eq("member_id", value: memberId)
            .eq("status", value: MembershipStatus.active.rawValue)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Goes through the RPC because the last owner must be refused — a chapter with no
    /// owner has nobody who can ever approve anyone again.
    public func leaveChapter(chapterId: UUID) async throws {
        try await client
            .rpc("leave_chapter", params: LeaveParams(p_chapter_id: chapterId))
            .execute()
        WidgetManager.shared.reloadTimelines()
    }

    /// `access_level` nunca é concedido a `authenticated` — é isso que impede
    /// auto-promoção — então quem escreve a coluna é sempre uma função no servidor.
    public func setAccessLevel(membershipId: UUID, level: AccessLevel) async throws {
        try await client
            .rpc("set_membership_access_level", params: AccessLevelParams(
                p_membership_id: membershipId,
                p_access_level: level.rawValue
            ))
            .execute()
    }

    public func transferOwnership(toMembershipId: UUID) async throws {
        try await client
            .rpc("transfer_chapter_ownership", params: TransferParams(p_to_membership_id: toMembershipId))
            .execute()
    }

    /// Função e não policy: abrir `member` por policy daria a todo administrador de
    /// plataforma leitura irrestrita da tabela de pessoas.
    public func platformAdmins() async throws -> [PlatformAdmin] {
        try await client.rpc("platform_admins").execute().value
    }

    /// `is_platform_admin` nunca é concedida a `authenticated`, então quem escreve a
    /// coluna é sempre a função no servidor -- e ela recusa quem ainda não tem o
    /// status. Não há caminho para se conceder sozinho.
    public func grantPlatformAdmin(cid: String) async throws {
        try await client
            .rpc("grant_platform_admin", params: GrantPlatformParams(p_cid: cid))
            .execute()
    }

    public func revokePlatformAdmin(memberId: UUID) async throws {
        try await client
            .rpc("set_platform_admin", params: PlatformAdminParams(
                p_member_id: memberId, p_is_admin: false
            ))
            .execute()
    }
}
