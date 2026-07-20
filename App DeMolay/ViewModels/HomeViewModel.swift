import Foundation
import Observation

@Observable
public final class HomeViewModel {
    public var events: [Event] = []
    public var goals: [Goal] = []
    public var committees: [Committee] = []
    public var tasks: [ChapterTask] = []
    
    public var isLoading = false
    public var errorMessage: String?
    
    private let eventService: EventServiceProtocol
    private let goalService: GoalServiceProtocol
    
    public init(eventService: EventServiceProtocol = MockEventService(),
                goalService: GoalServiceProtocol = MockGoalService()) {
        self.eventService = eventService
        self.goalService = goalService
    }
    
    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let mockChapterId = UUID()
            events = try await eventService.fetchEvents(for: mockChapterId)
            goals = try await goalService.fetchGoals(for: mockChapterId)
            
            let mockCommitteeId1 = UUID()
            let mockCommitteeId2 = UUID()
            
            committees = [
                Committee(id: mockCommitteeId1, chapterId: UUID(), name: "Sindicância", chairmanId: nil, createdAt: Date()),
                Committee(id: mockCommitteeId2, chapterId: UUID(), name: "Hospitalaria", chairmanId: nil, createdAt: Date())
            ]
            
            tasks = [
                ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: mockCommitteeId1, title: "Entrevistar fulano", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400), createdAt: Date()),
                ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: mockCommitteeId1, title: "Votar em plenário", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(-86400), createdAt: Date())
            ]
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
