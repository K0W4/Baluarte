import Foundation
import Observation
import SwiftUI

public enum TasksFilterSegment: String, CaseIterable, Identifiable {
    case todas = "Todas as Tarefas"
    case minhas = "Minhas Tarefas"
    public var id: String { rawValue }
}

@MainActor
@Observable
public final class TasksViewModel {
    public var allTasks: [ChapterTask] = []
    public var selectedSegment: TasksFilterSegment = .todas

    public var isLoading = false
    public var errorMessage: String?

    private let taskService: TaskServiceProtocol

    public init(taskService: TaskServiceProtocol = MockTaskService()) {
        self.taskService = taskService
    }

    public var currentUserId: UUID = UUID()

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            allTasks = try await taskService.fetchTasks(for: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
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

    public var completedTasks: [ChapterTask] {
        allTasks.filter { $0.isCompleted }
    }

    // MARK: - Filtered Computed Properties

    public var displayIndividualTasks: [ChapterTask] {
        if selectedSegment == .todas { return [] }
        if isLoading { return ChapterTask.skeletonList }
        return generalTasks.filter { $0.assigneeId == currentUserId }
    }

    public var displayCommitteeTasks: [UUID: [ChapterTask]] {
        if isLoading {
            return [UUID(): ChapterTask.skeletonList]
        }
        if selectedSegment == .todas {
            return committeeTasks
        }
        var filtered: [UUID: [ChapterTask]] = [:]
        for (key, value) in committeeTasks {
            let myTasks = value.filter { $0.assigneeId == currentUserId }
            if !myTasks.isEmpty { filtered[key] = myTasks }
        }
        return filtered
    }

    public var displayCompletedTasks: [ChapterTask] {
        if isLoading { return [] }
        if selectedSegment == .todas {
            return completedTasks
        }
        return completedTasks.filter { $0.assigneeId == currentUserId }
    }

    public var progressCounts: (completed: Int, total: Int) {
        if isLoading { return (0, 0) }
        let completed = displayCompletedTasks.count
        let activeIndividual = displayIndividualTasks.count
        let activeCommittee = displayCommitteeTasks.values.reduce(0) { $0 + $1.count }
        return (completed, completed + activeIndividual + activeCommittee)
    }

    // MARK: - Actions

    public func toggleTaskCompletion(task: ChapterTask) async {
        do {
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                withAnimation {
                    allTasks[index].isCompleted.toggle()
                }
                if allTasks[index].isCompleted {
                    HapticManager.shared.notification(type: .success)
                } else {
                    HapticManager.shared.impact(style: .light)
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
        if id == MockTaskService.committee1Id { return "Comissão de Sindicância" }
        if id == MockTaskService.committee2Id { return "Comissão de Hospitalaria" }
        return "Comissão Específica"
    }

    public func deleteTask(task: ChapterTask) async {
        let originalTasks = allTasks

        withAnimation {
            allTasks.removeAll { $0.id == task.id }
        }

        do {
            try await taskService.deleteTask(taskId: task.id)
        } catch {
            withAnimation {
                allTasks = originalTasks
            }
        }
    }
}
