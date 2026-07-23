import Foundation
import Supabase

public final class SupabaseCommitteeService: CommitteeServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    public init() {}
    
    public func fetchCommittees(for chapterId: UUID) async throws -> [Committee] {
        let response: [Committee] = try await client
            .from("committee")
            .select()
            .eq("chapter_id", value: chapterId)
            .execute()
            .value
        
        return response
    }
    
    public func createCommittee(_ committee: Committee) async throws {
        try await client
            .from("committee")
            .insert(committee)
            .execute()
    }
    
    public func updateCommittee(_ committee: Committee) async throws {
        try await client
            .from("committee")
            .update(committee)
            .eq("id", value: committee.id)
            .execute()
    }
    
    public func deleteCommittee(committeeId: UUID) async throws {
        try await client
            .from("committee")
            .delete()
            .eq("id", value: committeeId)
            .execute()
    }
}
