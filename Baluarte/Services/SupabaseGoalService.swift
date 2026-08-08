import Foundation
import Supabase
import WidgetKit

public final class SupabaseGoalService: BaseSupabaseService<Goal>, GoalServiceProtocol {
    
    public init() {
        super.init(tableName: "goal")
    }
    
    public func fetchGoals(for chapterId: UUID) async throws -> [Goal] {
        try await fetchAll(chapterId: chapterId)
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
        WidgetManager.shared.reloadTimelines()
    }
    
    public func createGoal(_ goal: Goal) async throws {
        try await create(goal)
    }
    
    public func updateGoal(_ goal: Goal) async throws {
        try await update(goal)
    }
    
    public func deleteGoal(goalId: UUID) async throws {
        try await delete(id: goalId)
    }
}
