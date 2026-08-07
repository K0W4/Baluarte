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
}
