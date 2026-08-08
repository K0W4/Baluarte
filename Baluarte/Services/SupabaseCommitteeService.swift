import Foundation
import Supabase

public final class SupabaseCommitteeService: BaseSupabaseService<Committee>, CommitteeServiceProtocol {
    
    public init() {
        super.init(tableName: "committee")
    }
    
    public func fetchCommittees(for chapterId: UUID) async throws -> [Committee] {
        try await fetchAll(chapterId: chapterId)
    }
    
    public func createCommittee(_ committee: Committee) async throws {
        try await create(committee)
    }
    
    public func updateCommittee(_ committee: Committee) async throws {
        try await update(committee)
    }
    
    public func deleteCommittee(committeeId: UUID) async throws {
        try await delete(id: committeeId)
    }
}
