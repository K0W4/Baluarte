import Foundation
import SwiftUI

@Observable
@MainActor
public final class CommitteeDetailViewModel {
    public var name: String
    
    public var isLoading: Bool = false
    public var isFetchingMembers: Bool = false
    public var errorMessage: String? = nil
    
    public var committeeMembers: [Member] {
        availableMembers.filter { selectedMembersIds.contains($0.id) }
    }
    
    public var availableMembers: [Member] = []
    public var selectedMembersIds: Set<UUID> = []
    public var chairmanId: UUID? = nil
    
    public var committeeTasks: [ChapterTask] = []
    
    private let committeeService: CommitteeServiceProtocol
    private let memberService: MemberServiceProtocol
    private let taskService: TaskServiceProtocol
    
    private var committee: Committee
    
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        chairmanId != nil
    }
    
    public var hasChanges: Bool {
        committee.name != name ||
        committee.chairmanId != chairmanId ||
        Set(committee.memberIds ?? []) != selectedMembersIds
    }
    
    public init(
        committee: Committee,
        committeeService: CommitteeServiceProtocol = Services.committee,
        memberService: MemberServiceProtocol = Services.member,
        taskService: TaskServiceProtocol = Services.task
    ) {
        self.committee = committee
        self.committeeService = committeeService
        self.memberService = memberService
        self.taskService = taskService
        
        self.name = committee.name
        self.chairmanId = committee.chairmanId
        self.selectedMembersIds = Set(committee.memberIds ?? [])
    }
    
    public func loadData() async {
        isFetchingMembers = true
        errorMessage = nil
        do {
            async let fetchMembers = memberService.fetchMembers(for: committee.chapterId)
            async let fetchTasks = taskService.fetchTasks(forChapter: Constants.testChapterId)
            
            let (members, tasks) = try await (fetchMembers, fetchTasks)
            
            self.availableMembers = members
            self.committeeTasks = tasks.filter { $0.committeeId == committee.id }
            
            isFetchingMembers = false
        } catch {
            if error is CancellationError { return }
            print("❌ Supabase Error: \(error)")
            errorMessage = "Erro ao carregar dados da comissão."
            isFetchingMembers = false
        }
    }
    
    public func removeMember(_ memberId: UUID) {
        selectedMembersIds.remove(memberId)
        if chairmanId == memberId {
            chairmanId = nil
        }
    }
    
    public func addMember(_ memberId: UUID) {
        selectedMembersIds.insert(memberId)
    }
    
    public func toggleTaskCompletion(taskId: UUID) async {
        guard let index = committeeTasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        let originalTask = committeeTasks[index]
        let newStatus = !originalTask.isCompleted
        
        committeeTasks[index].isCompleted = newStatus
        
        do {
            try await taskService.toggleTaskCompletion(taskId: taskId, isCompleted: newStatus)
        } catch {
            if error is CancellationError { return }
            committeeTasks[index].isCompleted = !newStatus
            errorMessage = "Erro ao atualizar a tarefa."
        }
    }
    
    public func saveChanges() async -> Bool {
        guard isValid && hasChanges else { return false }
        
        isLoading = true
        errorMessage = nil
        
        var updatedCommittee = committee
        updatedCommittee.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedCommittee.chairmanId = chairmanId
        updatedCommittee.memberIds = Array(selectedMembersIds)
        
        do {
            try await committeeService.updateCommittee(updatedCommittee)
            self.committee = updatedCommittee
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = "Erro ao atualizar a comissão."
            isLoading = false
            return false
        }
    }
    
    public func deleteCommittee() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await committeeService.deleteCommittee(committeeId: committee.id)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = "Erro ao excluir a comissão."
            isLoading = false
            return false
        }
    }
}
