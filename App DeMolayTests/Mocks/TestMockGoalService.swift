import Foundation
@testable import App_DeMolay

public final class TestMockGoalService: GoalServiceProtocol {
    public var shouldThrowError = false
    public var goalsToReturn: [Goal] = []
    
    public var fetchGoalsCallCount = 0
    public var updateProgressCallCount = 0
    public var createGoalCallCount = 0
    public var updateGoalCallCount = 0
    public var deleteGoalCallCount = 0
    
    public init() {}
    
    public func fetchGoals(for chapterId: UUID) async throws -> [Goal] {
        fetchGoalsCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockGoalService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch goals"])
        }
        return goalsToReturn
    }
    
    public func updateProgress(goalId: UUID, newCurrentValue: Double) async throws {
        updateProgressCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockGoalService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to update progress"])
        }
    }
    
    public func createGoal(_ goal: Goal) async throws {
        createGoalCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockGoalService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create goal"])
        }
    }
    
    public func updateGoal(_ goal: Goal) async throws {
        updateGoalCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockGoalService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to update goal"])
        }
    }
    
    public func deleteGoal(goalId: UUID) async throws {
        deleteGoalCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockGoalService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to delete goal"])
        }
    }
}
