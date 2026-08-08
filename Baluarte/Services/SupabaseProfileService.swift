import Foundation
import Supabase

public final class SupabaseProfileService: ProfileServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    public init() {}

    private struct ProfileInsert: Encodable {
        let id: UUID
        let full_name: String
        let cid: String?
        let birthdate: String?
    }

    /// Only the columns granted to `authenticated`. Sending `id`, `is_platform_admin`
    /// or `created_at` in a PATCH body is rejected with 403 by column privilege.
    private struct ProfileUpdate: Encodable {
        let full_name: String
        let cid: String?
        let birthdate: String?
    }

    private struct ActiveChapterUpdate: Encodable {
        let active_chapter_id: UUID?
    }

    private static func encodeDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    public func fetchProfile(id: UUID) async throws -> UserProfile? {
        let response: [UserProfile] = try await client
            .from("member")
            .select()
            .eq("id", value: id)
            .execute()
            .value

        return response.first
    }

    public func createProfile(_ profile: UserProfile) async throws {
        let payload = ProfileInsert(
            id: profile.id,
            full_name: profile.fullName,
            cid: profile.cid,
            birthdate: Self.encodeDate(profile.birthdate)
        )

        try await client.from("member").insert(payload).execute()
    }

    public func updateProfile(_ profile: UserProfile) async throws {
        let payload = ProfileUpdate(
            full_name: profile.fullName,
            cid: profile.cid,
            birthdate: Self.encodeDate(profile.birthdate)
        )

        try await client
            .from("member")
            .update(payload)
            .eq("id", value: profile.id)
            .execute()

        // The roster row is authoritative for what the chapter sees, so the person's
        // own edits have to reach it too — otherwise the save looks applied but the
        // members list keeps showing the old name.
        let rosterPayload = ProfileUpdate(
            full_name: profile.fullName,
            cid: profile.cid,
            birthdate: Self.encodeDate(profile.birthdate)
        )

        try await client
            .from("chapter_membership")
            .update(rosterPayload)
            .eq("member_id", value: profile.id)
            .execute()

        WidgetManager.shared.reloadTimelines()
    }

    public func updateActiveChapter(memberId: UUID, chapterId: UUID?) async throws {
        try await client
            .from("member")
            .update(ActiveChapterUpdate(active_chapter_id: chapterId))
            .eq("id", value: memberId)
            .execute()
    }
}
