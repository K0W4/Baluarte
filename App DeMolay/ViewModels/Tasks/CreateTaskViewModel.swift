import Foundation
import SwiftUI

@Observable
@MainActor
public final class CreateTaskViewModel {
    public var title: String = ""
    public var dueDate: Date = Date().addingTimeInterval(86400 * 7)
    public var selectedCommitteeId: UUID? = nil
    
    public var committees: [Committee] = []
    
    public var isLoading: Bool = false
    public var isFetchingCommittees: Bool = false
    public var errorMessage: String? = nil
    
    private let taskService: TaskServiceProtocol
    private let committeeService: CommitteeServiceProtocol
    private let chapterId: UUID
    private let currentMembershipId: UUID
    private let accessLevel: AccessLevel

    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(
        chapterId: UUID,
        currentMembershipId: UUID,
        accessLevel: AccessLevel = .member,
        taskService: TaskServiceProtocol = Services.task,
        committeeService: CommitteeServiceProtocol = Services.committee
    ) {
        self.taskService = taskService
        self.committeeService = committeeService
        self.chapterId = chapterId
        self.currentMembershipId = currentMembershipId
        self.accessLevel = accessLevel
    }

    /// Only committees the person belongs to, because `task_insert` rejects anything
    /// else. Admins keep the full list — they may create work for any committee.
    func selectableCommittees(from all: [Committee]) -> [Committee] {
        guard accessLevel < .admin else { return all }
        return all.filter {
            $0.chairmanId == currentMembershipId ||
            $0.memberIds?.contains(currentMembershipId) == true
        }
    }

    public func loadCommittees() async {
        isFetchingCommittees = true
        do {
            let all = try await committeeService.fetchCommittees(for: chapterId)
            self.committees = selectableCommittees(from: all)
            isFetchingCommittees = false
        } catch {
            if error is CancellationError { return }
            isFetchingCommittees = false
        }
    }
    
    public func saveTask() async -> Bool {
        guard isValid else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let newTask = ChapterTask(
            id: UUID(),
            chapterId: chapterId,
            creatorId: currentMembershipId,
            assigneeId: currentMembershipId,
            committeeId: selectedCommitteeId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: "",
            isCompleted: false,
            dueDate: dueDate,
            createdAt: Date()
        )
        
        do {
            try await taskService.createTask(newTask)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = "Erro ao criar a tarefa. Tente novamente."
            isLoading = false
            return false
        }
    }
}
