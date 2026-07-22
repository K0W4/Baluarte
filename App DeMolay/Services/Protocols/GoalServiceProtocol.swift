import Foundation

public protocol GoalServiceProtocol {
    func fetchGoals(for chapterId: UUID) async throws -> [Goal]
    func updateProgress(goalId: UUID, newCurrentValue: Double) async throws
}
