import Foundation
import Supabase

/// Adapts the roster-shaped `Member` the UI works with onto `chapter_membership`.
/// Reads go through the `chapter_roster` projection; writes name only the columns
/// granted to `authenticated`, because `access_level` and `approved_by` are withheld
/// and a payload touching them is rejected with 403.
public final class SupabaseMemberService: MemberServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    public init() {}

    private struct RosterInsert: Encodable {
        let chapter_id: UUID
        let full_name: String
        let category: String
        let role: String?
        let cid: String?
        let birthdate: String?
        let status: String
    }

    private struct RosterUpdate: Encodable {
        let full_name: String
        let category: String
        let role: String?
        let cid: String?
        let birthdate: String?
    }

    private static func encodeDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    public func fetchMembers(for chapterId: UUID) async throws -> [Member] {
        try await client
            .from("chapter_roster")
            .select()
            .eq("chapter_id", value: chapterId)
            .execute()
            .value
    }

    public func createMember(_ member: Member) async throws {
        guard let chapterId = member.chapterId else {
            throw AppError.validationFailed("Não foi possível identificar o Capítulo do membro.")
        }

        let category = MembershipCategory(
            isActive: member.isActive,
            isSenior: member.isSenior,
            isMason: member.isMason
        )

        let payload = RosterInsert(
            chapter_id: chapterId,
            full_name: member.fullName,
            category: category.rawValue,
            role: member.role,
            cid: member.cid,
            birthdate: Self.encodeDate(member.birthdate),
            status: MembershipStatus.active.rawValue
        )

        try await client.from("chapter_membership").insert(payload).execute()
        WidgetManager.shared.reloadTimelines()
    }

    public func updateMember(_ member: Member) async throws {
        let category = MembershipCategory(
            isActive: member.isActive,
            isSenior: member.isSenior,
            isMason: member.isMason
        )

        let payload = RosterUpdate(
            full_name: member.fullName,
            category: category.rawValue,
            role: member.role,
            cid: member.cid,
            birthdate: Self.encodeDate(member.birthdate)
        )

        try await client
            .from("chapter_membership")
            .update(payload)
            .eq("id", value: member.id)
            .execute()
        WidgetManager.shared.reloadTimelines()
    }

    public func deleteMember(memberId: UUID) async throws {
        try await client
            .from("chapter_membership")
            .delete()
            .eq("id", value: memberId)
            .execute()
        WidgetManager.shared.reloadTimelines()
    }
}
