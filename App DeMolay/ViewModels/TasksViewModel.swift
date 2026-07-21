import Foundation
import Observation
import SwiftUI

@Observable
public final class TasksViewModel {
    public var allTasks: [ChapterTask] = []
    
    public var isLoading = false
    public var errorMessage: String?
    
    private let taskService: TaskServiceProtocol
    
    public init(taskService: TaskServiceProtocol = MockTaskService()) {
        self.taskService = taskService
    }
    
    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let mockUserId = UUID()
            allTasks = try await taskService.fetchTasks(for: mockUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public var activeTasks: [ChapterTask] {
        allTasks.filter { !$0.isCompleted }
    }
    
    public var generalTasks: [ChapterTask] {
        activeTasks.filter { $0.committeeId == nil }
    }
    
    public var committeeTasks: [UUID: [ChapterTask]] {
        let tasksWithCommittee = activeTasks.filter { $0.committeeId != nil }
        return Dictionary(grouping: tasksWithCommittee, by: { $0.committeeId ?? UUID() })
    }
    
    @MainActor
    public func toggleTaskCompletion(task: ChapterTask) async {
        do {
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                withAnimation {
                    allTasks[index].isCompleted.toggle()
                }
            }
            
            try await taskService.toggleTaskCompletion(taskId: task.id, isCompleted: !task.isCompleted)
        } catch {
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                withAnimation {
                    allTasks[index].isCompleted.toggle()
                }
            }
        }
    }
    
    public func committeeName(for id: UUID) -> String {
        return "Comissão Específica"
    }
}
