import SwiftUI
import Observation

@Observable
public final class SmartSummaryViewModel {
    public var generatedSummary: String = ""
    public var isGenerating: Bool = false
    public var errorMessage: String? = nil

    /// O aparelho não tem o modelo. É diferente de uma falha temporária: oferecer "tentar
    /// de novo" aqui é convidar a pessoa a repetir algo que nunca vai funcionar.
    public var isUnavailableOnThisDevice: Bool = false

    private let intelligenceService: IntelligenceServiceProtocol
    private let eventService: EventServiceProtocol
    private let taskService: TaskServiceProtocol
    private let goalService: GoalServiceProtocol
    
    public init(
        intelligenceService: IntelligenceServiceProtocol = Services.intelligence, // Agora conectando ao modelo real por padrão
        eventService: EventServiceProtocol = Services.event,
        taskService: TaskServiceProtocol = Services.task,
        goalService: GoalServiceProtocol = Services.goal
    ) {
        self.intelligenceService = intelligenceService
        self.eventService = eventService
        self.taskService = taskService
        self.goalService = goalService
    }
    
    @MainActor
    public func generateSummary(chapterId: UUID) async {
        guard !isGenerating else { return }
        
        self.isGenerating = true
        self.errorMessage = nil
        self.isUnavailableOnThisDevice = false
        self.generatedSummary = ""

        do {
            async let fetchEvents = eventService.fetchEvents(for: chapterId)
            async let fetchTasks = taskService.fetchTasks(forChapter: chapterId)
            async let fetchGoals = goalService.fetchGoals(for: chapterId)
            
            let (events, tasks, goals) = try await (fetchEvents, fetchTasks, fetchGoals)
            
            let context = IntelligenceContext(events: events, tasks: tasks, goals: goals)
            let stream = intelligenceService.generateSmartSummary(context: context)
            
            for try await token in stream {
                self.generatedSummary += token
            }
            
        } catch is IntelligenceUnavailableError {
            self.isUnavailableOnThisDevice = true
            self.errorMessage = IntelligenceUnavailableError().errorDescription
        } catch {
            // "Verifique o modelo" era mensagem escrita para quem programou: um membro do
            // Capítulo não sabe o que é o modelo, onde ele fica, nem como se verifica.
            self.errorMessage = AppError.from(error).userMessage
        }

        self.isGenerating = false
    }
}
