import Foundation
@testable import App_DeMolay

public final class TestMockTaskService: TaskServiceProtocol {
    public var shouldThrowError = false
    public var tasksToReturn: [ChapterTask] = []
    
    public var fetchTasksCallCount = 0
    public var toggleTaskCompletionCallCount = 0
    public var deleteTaskCallCount = 0
    public var createTaskCallCount = 0
    
    public init() {}
    
    public func fetchTasks(forChapter chapterId: UUID) async throws -> [ChapterTask] {
        fetchTasksCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockTaskService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch tasks"])
        }
        return tasksToReturn
    }
    
    public func toggleTaskCompletion(taskId: UUID, isCompleted: Bool) async throws {
        toggleTaskCompletionCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockTaskService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to toggle task completion"])
        }
    }
    
    public func deleteTask(taskId: UUID) async throws {
        deleteTaskCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockTaskService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to delete task"])
        }
    }
    
    public func createTask(_ task: ChapterTask) async throws {
        createTaskCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockTaskService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create task"])
        }
    }
}
