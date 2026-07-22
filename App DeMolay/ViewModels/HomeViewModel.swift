import Foundation
import Observation
import SwiftUI

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
    
    public let currentUserId = UUID()
    
    public init(eventService: EventServiceProtocol = MockEventService(),
                goalService: GoalServiceProtocol = MockGoalService()) {
        self.eventService = eventService
        self.goalService = goalService
    }
    
    public func toggleTaskCompletion(taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    public func confirmAttendance(eventId: UUID) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            var attendees = events[index].confirmedAttendees ?? []
            if attendees.contains(currentUserId) {
                attendees.removeAll { $0 == currentUserId }
            } else {
                attendees.append(currentUserId)
            }
            events[index].confirmedAttendees = attendees
        }
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
            let mockCommitteeId3 = UUID()
            let mockCommitteeId4 = UUID()
            
            committees = [
                Committee(id: mockCommitteeId1, chapterId: UUID(), name: "Sindicância", chairmanId: nil, createdAt: Date()),
                Committee(id: mockCommitteeId2, chapterId: UUID(), name: "Hospitalaria", chairmanId: nil, createdAt: Date()),
                Committee(id: mockCommitteeId3, chapterId: UUID(), name: "Finanças", chairmanId: nil, createdAt: Date()),
                Committee(id: mockCommitteeId4, chapterId: UUID(), name: "Eventos", chairmanId: nil, createdAt: Date())
            ]
            
            tasks = [
                ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: mockCommitteeId1, title: "Entrevistar candidato", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400), createdAt: Date()),
                ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: mockCommitteeId2, title: "Organizar doações", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400 * 2), createdAt: Date()),
                ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: mockCommitteeId3, title: "Balanço mensal", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400 * 5), createdAt: Date()),
                ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: mockCommitteeId4, title: "Alugar espaço", description: "", isCompleted: true, dueDate: Date().addingTimeInterval(-86400), createdAt: Date())
            ]
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }
}
