import SwiftUI
import Observation

@Observable
public final class SmartSummaryViewModel {
    public var generatedSummary: String = ""
    public var isGenerating: Bool = false
    public var errorMessage: String? = nil
    
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
        self.generatedSummary = ""
        
        do {
            async let fetchEvents = eventService.fetchEvents(for: chapterId)
            async let fetchTasks = taskService.fetchTasks(forChapter: chapterId)
            async let fetchGoals = goalService.fetchGoals(for: chapterId)
            
            let (events, tasks, goals) = try await (fetchEvents, fetchTasks, fetchGoals)
            
            let context = IntelligenceContext(events: events, tasks: tasks, goals: goals)
            let stream = intelligenceService.generateSmartSummary(context: context)
            
            for try await token in stream {
                // Efeito nativo "Typing" token a token
                self.generatedSummary += token
            }
            
        } catch {
            self.errorMessage = "Falha ao gerar o resumo inteligente. Verifique o modelo."
            print("Intelligence error: \(error)")
        }
        
        self.isGenerating = false
    }
}
