import Foundation

public final class MockTaskService: TaskServiceProtocol {
    public init() {}
    
    public func fetchTasks(for userId: UUID) async throws -> [ChapterTask] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let chapterId = UUID()
        let committee1 = UUID()
        let committee2 = UUID()
        
        return [
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: userId, assigneeId: userId, committeeId: nil, title: "Pagar mensalidade", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400 * 2), createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: UUID(), assigneeId: userId, committeeId: committee1, title: "Entrevistar candidato", description: "Ligar para o candidato e marcar entrevista", isCompleted: false, dueDate: Date().addingTimeInterval(86400), createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: UUID(), assigneeId: userId, committeeId: committee2, title: "Comprar mantimentos", description: "", isCompleted: false, dueDate: nil, createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: userId, assigneeId: userId, committeeId: nil, title: "Estudar ritual", description: "", isCompleted: true, dueDate: nil, createdAt: Date())
        ]
    }
    
    public func toggleTaskCompletion(taskId: UUID, isCompleted: Bool) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
}
