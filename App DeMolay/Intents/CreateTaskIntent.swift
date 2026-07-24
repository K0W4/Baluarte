import AppIntents
import Foundation
import Supabase
import Auth

public struct CreateTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Nova Tarefa do Capítulo"
    public static var description = IntentDescription("Cria uma nova tarefa geral para o Capítulo.")
    
    @Parameter(title: "Título da Tarefa")
    public var title: String
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let userId = Constants.testUserId
        
        // Em um app real, o chapterId viria do perfil do usuário. 
        // Estamos usando o testChapterId provisoriamente como no resto do app.
        let newTask = ChapterTask(
            id: UUID(),
            chapterId: Constants.testChapterId,
            creatorId: userId,
            assigneeId: nil,
            committeeId: nil,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: "",
            isCompleted: false,
            dueDate: nil,
            createdAt: Date()
        )
        
        try await Services.task.createTask(newTask)
        
        return .result(dialog: "Pronto, adicionei a tarefa \(title) no Capítulo.")
    }
}
