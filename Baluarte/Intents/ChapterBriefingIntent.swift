import AppIntents
import Foundation

public struct ChapterBriefingIntent: AppIntent {
    public static var title: LocalizedStringResource = "Resumo do Capítulo"
    public static var description = IntentDescription("Fornece um resumo das tarefas pendentes e do próximo evento do Capítulo.")
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let chapterId = await UserDefaultsManager.shared.currentChapterId else {
            return .result(dialog: "Você precisa estar autenticado para ver o resumo do Capítulo.")
        }
        
        let events = try? await Services.event.fetchEvents(for: chapterId)
        let tasks = try? await Services.task.fetchTasks(forChapter: chapterId)
        
        let pendingTasks = tasks?.filter { !$0.isCompleted } ?? []
        
        var dialog = ""
        if pendingTasks.count == 0 {
            dialog += "Você não tem nenhuma tarefa pendente. "
        } else if pendingTasks.count == 1 {
            dialog += "Você tem 1 tarefa pendente. "
        } else {
            dialog += "Você tem \(pendingTasks.count) tarefas pendentes. "
        }
        
        if let events = events {
            let upcomingEvents = events.filter { $0.scheduledDate > Date() }.sorted { $0.scheduledDate < $1.scheduledDate }
            if let nextEvent = upcomingEvents.first {
                let weekday = nextEvent.scheduledDate.formatted(.dateTime.weekday(.wide))
                dialog += "O próximo evento é \(nextEvent.title) neste(a) \(weekday)."
            } else {
                dialog += "Não há próximos eventos agendados."
            }
        }
        
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}
