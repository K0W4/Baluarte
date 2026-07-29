import Foundation

public struct IntelligenceContext: Sendable {
    public let events: [Event]
    public let tasks: [ChapterTask]
    public let goals: [Goal]
    
    public init(events: [Event], tasks: [ChapterTask], goals: [Goal]) {
        self.events = events
        self.tasks = tasks
        self.goals = goals
    }

    
    public func buildPrompt() -> String {
        var prompt = "Analise os dados do Capítulo DeMolay abaixo. Responda com EXATAMENTE 2 a 3 frases curtas e motivadoras. Máximo 150 palavras. Não repita informações.\n\n"
        
        let upcomingEvents = events.prefix(3)
        if upcomingEvents.isEmpty {
            prompt += "Eventos: Nenhum próximo.\n"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let eventList = upcomingEvents.map { "\($0.title) (\(formatter.string(from: $0.scheduledDate)))" }.joined(separator: ", ")
            prompt += "Eventos: \(eventList)\n"
        }
        
        let pendingTasks = tasks.filter { !$0.isCompleted }.prefix(3)
        if pendingTasks.isEmpty {
            prompt += "Tarefas pendentes: Nenhuma.\n"
        } else {
            let taskList = pendingTasks.map { $0.title }.joined(separator: ", ")
            prompt += "Tarefas pendentes: \(taskList)\n"
        }
        
        let activeGoals = goals.filter { !$0.isCompleted }.prefix(2)
        if activeGoals.isEmpty {
            prompt += "Metas: Nenhuma ativa.\n"
        } else {
            let goalList = activeGoals.map { "\($0.title) (\(Int($0.progressPercentage * 100))%)" }.joined(separator: ", ")
            prompt += "Metas: \(goalList)\n"
        }
        
        prompt += "\nResuma em 2-3 frases motivadoras:"
        return prompt
    }
}
