import Foundation
import Supabase

public final class ChapterService: ChapterServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    public init() {}

    private struct SearchParams: Encodable {
        let p_query: String?
        let p_uf: String?
    }

    /// Only the columns granted to `authenticated`: `status`, `reviewed_by` and
    /// `reviewed_at` are withheld so a request always starts as pending.
    private struct RequestInsert: Encodable {
        let requested_by: UUID
        let name: String
        let number: Int
        let uf: String
        let city: String?
        let note: String?
    }

    /// Search runs server-side so accents and case are handled by the same `unaccent`
    /// index the registry is built on — "sao" finds "São".
    public func searchChapters(query: String?, uf: String?) async throws -> [Chapter] {
        try await client
            .rpc("search_chapters", params: SearchParams(p_query: query, p_uf: uf))
            .execute()
            .value
    }

    /// Direct read rather than filtering a search result: a chapter under review is
    /// excluded from search, but someone already bonded to it still needs its name.
    public func fetchChapter(id: UUID) async throws -> Chapter? {
        let rows: [Chapter] = try await client
            .from("chapter")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    public func requestChapter(_ request: ChapterRequest) async throws {
        let payload = RequestInsert(
            requested_by: request.requestedBy,
            name: request.name,
            number: request.number,
            uf: request.uf,
            city: request.city,
            note: request.note
        )

        try await client.from("chapter_request").insert(payload).execute()
    }

    private struct ReviewParams: Encodable {
        let p_request_id: UUID
        let p_approved: Bool
        let p_reason: String?
    }

    /// Função e não policy, pela mesma razão de `platform_admins()`: quem revisa
    /// precisa da lista de pedidos, não de leitura da tabela de pessoas.
    public func pendingChapterRequests() async throws -> [PendingChapterRequest] {
        try await client.rpc("pending_chapter_requests").execute().value
    }

    /// `chapter` não tem grant de insert para `authenticated` -- um Capítulo é
    /// conferido contra o registro oficial da Ordem, nunca criado de dentro do app.
    /// Só a função no servidor escreve ali.
    public func reviewChapterRequest(id: UUID, approved: Bool, reason: String?) async throws {
        try await client
            .rpc("review_chapter_request", params: ReviewParams(
                p_request_id: id, p_approved: approved, p_reason: reason
            ))
            .execute()
    }
}
