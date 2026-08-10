import Foundation
import Supabase

public final class SupabaseJoinRequestService: JoinRequestServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    public init() {}

    private static let proofBucket = "bootstrap-proof"

    private struct RequestInsert: Encodable {
        let chapter_id: UUID
        let member_id: UUID
        let kind: String
        let message: String?
        let cid_snapshot: String?
        let proof_path: String?
    }

    private struct StatusUpdate: Encodable {
        let status: String
    }

    private struct ApproveParams: Encodable {
        let p_request_id: UUID
        let p_access_level: String
        let p_category: String
        let p_role: String?
        let p_link_membership_id: UUID?
    }

    private struct RejectParams: Encodable {
        let p_request_id: UUID
        let p_reason: String?
    }

    /// The request row plus the applicant's name, which PostgREST can embed through the
    /// member foreign key — one round trip instead of N.
    private struct PendingRow: Decodable {
        struct Applicant: Decodable { let full_name: String }
        let id: UUID
        let chapter_id: UUID
        let member_id: UUID
        let kind: JoinRequestKind
        let status: JoinRequestStatus
        let message: String?
        let cid_snapshot: String?
        let created_at: Date
        let reject_reason: String?
        let member: Applicant?
    }

    public func createRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?) async throws -> JoinRequest {
        let payload = RequestInsert(
            chapter_id: chapterId,
            member_id: memberId,
            kind: JoinRequestKind.chapterJoin.rawValue,
            message: message,
            cid_snapshot: cid,
            proof_path: nil
        )

        return try await client
            .from("join_request")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    /// Caminho `{auth.uid()}/{uuid}.jpg`: a primeira pasta é o dono, que é exatamente
    /// o que as policies do Storage conferem.
    public func uploadProof(memberId: UUID, imageData: Data) async throws -> String {
        let path = "\(memberId.uuidString)/\(UUID().uuidString).jpg"

        try await client.storage
            .from(Self.proofBucket)
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        return path
    }

    public func createBootstrapRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?, proofPath: String) async throws -> JoinRequest {
        let payload = RequestInsert(
            chapter_id: chapterId,
            member_id: memberId,
            kind: JoinRequestKind.chapterBootstrap.rawValue,
            message: message,
            cid_snapshot: cid,
            proof_path: proofPath
        )

        return try await client
            .from("join_request")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    /// Vai por RPC porque quem revisa não é admin de nenhum desses Capítulos — é a
    /// única leitura do app que atravessa Capítulos de propósito.
    public func fetchPendingBootstrapRequests() async throws -> [BootstrapRequest] {
        try await client
            .rpc("pending_bootstrap_requests")
            .execute()
            .value
    }

    public func signedProofURL(path: String) async throws -> URL {
        try await client.storage
            .from(Self.proofBucket)
            .createSignedURL(path: path, expiresIn: 300)
    }

    public func fetchMyPendingRequest(memberId: UUID) async throws -> JoinRequest? {
        let rows: [JoinRequest] = try await client
            .from("join_request")
            .select()
            .eq("member_id", value: memberId)
            .eq("status", value: JoinRequestStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    public func fetchMyLatestRejectedRequest(memberId: UUID) async throws -> JoinRequest? {
        let rows: [JoinRequest] = try await client
            .from("join_request")
            .select()
            .eq("member_id", value: memberId)
            .eq("status", value: JoinRequestStatus.rejected.rawValue)
            .order("reviewed_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    /// Marcar como cancelada tira a recusa do caminho sem apagar o registro do que
    /// aconteceu — a mesma coluna de status que a policy já permite ao dono da linha.
    public func acknowledgeRejection(id: UUID) async throws {
        try await client
            .from("join_request")
            .update(StatusUpdate(status: JoinRequestStatus.cancelled.rawValue))
            .eq("id", value: id)
            .execute()
    }

    public func fetchPendingRequests(for chapterId: UUID) async throws -> [PendingJoinRequest] {
        let rows: [PendingRow] = try await client
            .from("join_request")
            // `join_request` referencia `member` duas vezes -- `member_id`, quem pediu, e
            // `reviewed_by`, quem respondeu. Um embed por nome de tabela é ambíguo entre as
            // duas, e o PostgREST responde **300 Multiple Choices**, que o `AppError` não
            // mapeia e vira "o servidor está temporariamente indisponível". Efeito: a fila
            // de entrada nunca carregava, e a tela ainda afirmava não haver ninguém.
            //
            // Desambiguar pela coluna, e não pelo nome da constraint, é o que sobrevive a
            // um rename; o `member:` na frente preserva a chave que o `PendingRow` decodifica.
            .select("*, member:member_id(full_name)")
            .eq("chapter_id", value: chapterId)
            .eq("status", value: JoinRequestStatus.pending.rawValue)
            .order("created_at", ascending: true)
            .execute()
            .value

        return rows.map { row in
            PendingJoinRequest(
                request: JoinRequest(
                    id: row.id,
                    chapterId: row.chapter_id,
                    memberId: row.member_id,
                    kind: row.kind,
                    status: row.status,
                    message: row.message,
                    cidSnapshot: row.cid_snapshot,
                    createdAt: row.created_at,
                    rejectReason: row.reject_reason
                ),
                applicantName: row.member?.full_name ?? "Membro DeMolay"
            )
        }
    }

    public func cancelRequest(id: UUID) async throws {
        try await client
            .from("join_request")
            .update(StatusUpdate(status: JoinRequestStatus.cancelled.rawValue))
            .eq("id", value: id)
            .execute()
    }

    public func approve(requestId: UUID, accessLevel: AccessLevel, category: MembershipCategory, role: String?, linkMembershipId: UUID?) async throws {
        try await client
            .rpc("approve_join_request", params: ApproveParams(
                p_request_id: requestId,
                p_access_level: accessLevel.rawValue,
                p_category: category.rawValue,
                p_role: role,
                p_link_membership_id: linkMembershipId
            ))
            .execute()
        WidgetManager.shared.reloadTimelines()
    }

    public func reject(requestId: UUID, reason: String?) async throws {
        try await client
            .rpc("reject_join_request", params: RejectParams(
                p_request_id: requestId,
                p_reason: reason
            ))
            .execute()
    }
}
