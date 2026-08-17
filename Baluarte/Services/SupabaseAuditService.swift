import Foundation
import Supabase

public final class SupabaseAuditService: AuditServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    public init() {}

    private struct ChapterLogParams: Encodable {
        let p_chapter_id: UUID
        let p_limit: Int
        let p_before_id: Int?
    }

    private struct PlatformLogParams: Encodable {
        let p_limit: Int
        let p_before_id: Int?
    }

    public func chapterAccessLog(chapterId: UUID, limit: Int, beforeId: Int?) async throws -> [AccessChangeEntry] {
        try await client
            .rpc("chapter_access_log", params: ChapterLogParams(
                p_chapter_id: chapterId,
                p_limit: limit,
                p_before_id: beforeId
            ))
            .execute()
            .value
    }

    public func platformAccessLog(limit: Int, beforeId: Int?) async throws -> [AccessChangeEntry] {
        try await client
            .rpc("platform_access_log", params: PlatformLogParams(
                p_limit: limit,
                p_before_id: beforeId
            ))
            .execute()
            .value
    }
}
