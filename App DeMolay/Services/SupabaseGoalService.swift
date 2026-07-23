import Foundation
import Supabase

public final class SupabaseGoalService: GoalServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    public init() {}
    
    public func fetchGoals(for chapterId: UUID) async throws -> [Goal] {
        let response: [Goal] = try await client
            .from("goal")
            .select()
            .eq("chapter_id", value: chapterId)
            .execute()
            .value
        
        return response
    }
    
    public func updateProgress(goalId: UUID, newCurrentValue: Double) async throws {
        struct UpdateProgress: Codable {
            let current_value: Double
        }
        
        try await client
            .from("goal")
            .update(UpdateProgress(current_value: newCurrentValue))
            .eq("id", value: goalId)
            .execute()
    }
    
    public func createGoal(_ goal: Goal) async throws {
        try await client
            .from("goal")
            .insert(goal)
            .execute()
    }
    
    public func updateGoal(_ goal: Goal) async throws {
        try await client
            .from("goal")
            .update(goal)
            .eq("id", value: goal.id)
            .execute()
    }
    
    public func deleteGoal(goalId: UUID) async throws {
        try await client
            .from("goal")
            .delete()
            .eq("id", value: goalId)
            .execute()
    }
}
