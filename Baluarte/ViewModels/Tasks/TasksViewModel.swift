import Foundation
import Observation
import SwiftUI

public enum TasksFilterSegment: String, CaseIterable, Identifiable {
    case gerais = "Tarefas Gerais"
    case minhas = "Minhas Tarefas"
    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gerais: return String(localized: "Tarefas Gerais")
        case .minhas: return String(localized: "Minhas Tarefas")
        }
    }
}

@MainActor
@Observable
public final class TasksViewModel {
    public var allTasks: [ChapterTask] = []
    public var committees: [Committee] = []
    public var selectedSegment: TasksFilterSegment = .gerais

    public var isLoading = false
    public var errorMessage: String?

    private let taskService: TaskServiceProtocol
    private let committeeService: CommitteeServiceProtocol

    public init(taskService: TaskServiceProtocol = Services.task, committeeService: CommitteeServiceProtocol = Services.committee) {
        self.taskService = taskService
        self.committeeService = committeeService
    }

    public var currentMembershipId: UUID?
    public var currentChapterId: UUID?

    public func loadData(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil
        do {
            guard let chapterId = currentChapterId else { return }
            async let tasks = taskService.fetchTasks(forChapter: chapterId)
            async let comms = committeeService.fetchCommittees(for: chapterId)
            let (fetchedTasks, fetchedCommittees) = try await (tasks, comms)
            allTasks = fetchedTasks
            committees = fetchedCommittees
        } catch {
            if error is CancellationError { 
                withAnimation(.easeInOut(duration: 0.3)) { self.isLoading = false }
                return 
            }
            errorMessage = AppError.from(error).userMessage
        }
        if showLoading {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
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
        if isLoading { return ChapterTask.skeletonList }
        if selectedSegment == .gerais {
            return []
        }
        return generalTasks.filter { $0.assigneeId == currentMembershipId || $0.creatorId == currentMembershipId }
    }

    public var displayCommitteeTasks: [UUID: [ChapterTask]] {
        if isLoading {
            return [UUID(): ChapterTask.skeletonList]
        }
        if selectedSegment == .gerais {
            return committeeTasks
        }
        var filtered: [UUID: [ChapterTask]] = [:]
        for (key, value) in committeeTasks {
            let myTasks = value.filter { $0.assigneeId == currentMembershipId || $0.creatorId == currentMembershipId }
            if !myTasks.isEmpty { filtered[key] = myTasks }
        }
        return filtered
    }

    public var displayCompletedTasks: [ChapterTask] {
        if isLoading { return [] }
        if selectedSegment == .gerais {
            return completedTasks.filter { $0.committeeId != nil }
        }
        return completedTasks.filter { $0.assigneeId == currentMembershipId || $0.creatorId == currentMembershipId }
    }

    public var progressCounts: (completed: Int, total: Int) {
        if isLoading { return (0, 0) }
        let completed = displayCompletedTasks.count
        let activeIndividual = displayIndividualTasks.count
        let activeCommittee = displayCommitteeTasks.values.reduce(0) { $0 + $1.count }
        return (completed, completed + activeIndividual + activeCommittee)
    }

    // MARK: - Actions

    /// `true` quando o servidor aceitou. Quem chama precisa do retorno: o toast de sucesso
    /// era decidido pela cópia capturada antes do toggle, então uma recusa do servidor
    /// revertia o círculo e ainda exibia "Tarefa atualizada com sucesso!".
    @discardableResult
    public func toggleTaskCompletion(task: ChapterTask) async -> Bool {
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
            return true
        } catch {
            if error is CancellationError { return false }
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                withAnimation {
                    allTasks[index].isCompleted.toggle()
                }
            }
            HapticManager.shared.notification(type: .error)
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }

    public func committeeName(for id: UUID) -> String {
        return committees.first(where: { $0.id == id })?.name ?? String(localized: "Comissão")
    }

    public func deleteTask(task: ChapterTask) async {
        let originalTasks = allTasks

        withAnimation {
            allTasks.removeAll { $0.id == task.id }
        }

        do {
            try await taskService.deleteTask(taskId: task.id)
        } catch {
            if error is CancellationError { return }
            withAnimation {
                allTasks = originalTasks
            }
            // A linha sumia, voltava com animação, e nada explicava. A pessoa não sabia se
            // travou, se alguém recriou a tarefa, ou se ela tinha errado o toque.
            HapticManager.shared.notification(type: .error)
            errorMessage = AppError.from(error).userMessage
        }
    }
}
