import Foundation

public protocol GoalServiceProtocol {
    func fetchGoals(for chapterId: UUID) async throws -> [Goal]
    func updateProgress(goalId: UUID, newCurrentValue: Double) async throws
    func createGoal(_ goal: Goal) async throws
    func updateGoal(_ goal: Goal) async throws
    func deleteGoal(goalId: UUID) async throws
}
