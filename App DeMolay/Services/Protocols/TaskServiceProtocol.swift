import Foundation

public protocol TaskServiceProtocol {
    func fetchTasks(for userId: UUID) async throws -> [ChapterTask]
    func toggleTaskCompletion(taskId: UUID, isCompleted: Bool) async throws
    func deleteTask(taskId: UUID) async throws
}
