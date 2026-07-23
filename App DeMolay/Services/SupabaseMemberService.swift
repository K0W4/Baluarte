import Foundation
import Supabase

public final class SupabaseMemberService: MemberServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    public init() {}
    
    public func fetchMembers(for chapterId: UUID) async throws -> [Member] {
        let response: [Member] = try await client
            .from("member")
            .select()
            .eq("chapter_id", value: chapterId)
            .execute()
            .value
        
        return response
    }
    
    public func createMember(_ member: Member) async throws {
        try await client
            .from("member")
            .insert(member)
            .execute()
    }
    
    public func updateMember(_ member: Member) async throws {
        try await client
            .from("member")
            .update(member)
            .eq("id", value: member.id)
            .execute()
    }
    
    public func deleteMember(memberId: UUID) async throws {
        try await client
            .from("member")
            .delete()
            .eq("id", value: memberId)
            .execute()
    }
}
