import Foundation

public struct MockTaskService: TaskServiceProtocol {
    nonisolated public init() {}
    
    public static let committee1Id = UUID()
    public static let committee2Id = UUID()

    public func fetchTasks(for userId: UUID) async throws -> [ChapterTask] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let chapterId = UUID()
        
        return [
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: userId, assigneeId: userId, committeeId: nil, title: "Pagar mensalidade", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400 * 2), createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: userId, assigneeId: userId, committeeId: nil, title: "Responder e-mail do Grande Capítulo", description: "Verificar caixa de entrada e responder pendências", isCompleted: false, dueDate: Date().addingTimeInterval(-86400), createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: userId, assigneeId: userId, committeeId: nil, title: "Estudar ritual", description: "", isCompleted: true, dueDate: nil, createdAt: Date()),
            
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: UUID(), assigneeId: userId, committeeId: MockTaskService.committee1Id, title: "Entrevistar candidato", description: "Ligar para o candidato e marcar entrevista", isCompleted: false, dueDate: Date().addingTimeInterval(86400), createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: UUID(), assigneeId: userId, committeeId: MockTaskService.committee1Id, title: "Revisar documentos", description: "Analisar as fichas preenchidas", isCompleted: false, dueDate: Date().addingTimeInterval(86400 * 3), createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: UUID(), assigneeId: userId, committeeId: MockTaskService.committee1Id, title: "Relatório de sindicância", description: "", isCompleted: true, dueDate: nil, createdAt: Date()),
            
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: UUID(), assigneeId: userId, committeeId: MockTaskService.committee2Id, title: "Comprar mantimentos", description: "Para a próxima reunião de sábado", isCompleted: false, dueDate: nil, createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: chapterId, creatorId: UUID(), assigneeId: userId, committeeId: MockTaskService.committee2Id, title: "Ligar para abrigos locais", description: "Procurar instituições para a campanha de inverno", isCompleted: false, dueDate: Date().addingTimeInterval(86400 * 5), createdAt: Date())
        ]
    }
    
    public func toggleTaskCompletion(taskId: UUID, isCompleted: Bool) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    public func deleteTask(taskId: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    
    public func createTask(_ task: ChapterTask) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
