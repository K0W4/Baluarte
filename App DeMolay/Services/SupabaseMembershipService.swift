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
}
