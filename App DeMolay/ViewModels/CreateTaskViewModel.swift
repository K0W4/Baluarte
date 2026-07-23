import Foundation
import SwiftUI

@Observable
@MainActor
public final class CreateTaskViewModel {
    public var title: String = ""
    public var description: String = ""
    public var dueDate: Date = Date().addingTimeInterval(86400 * 7)
    public var selectedCommitteeId: UUID? = nil
    
    public var committees: [Committee] = []
    
    public var isLoading: Bool = false
    public var isFetchingCommittees: Bool = false
    public var errorMessage: String? = nil
    
    private let taskService: TaskServiceProtocol
    private let committeeService: CommitteeServiceProtocol
    private let chapterId: UUID
    private let currentUserId: UUID
    
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init(
        taskService: TaskServiceProtocol = MockTaskService(),
        committeeService: CommitteeServiceProtocol = MockCommitteeService(),
        chapterId: UUID = UUID(),
        currentUserId: UUID = UUID()
    ) {
        self.taskService = taskService
        self.committeeService = committeeService
        self.chapterId = chapterId
        self.currentUserId = currentUserId
    }
    
    public func loadCommittees() async {
        isFetchingCommittees = true
        do {
            self.committees = try await committeeService.fetchCommittees(for: chapterId)
            isFetchingCommittees = false
        } catch {
            isFetchingCommittees = false
            // Ignorar falha, apenas não mostraremos comissões
        }
    }
    
    public func saveTask() async -> Bool {
        guard isValid else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let newTask = ChapterTask(
            id: UUID(),
            chapterId: chapterId,
            creatorId: currentUserId,
            assigneeId: nil,
            committeeId: selectedCommitteeId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: false,
            dueDate: dueDate,
            createdAt: Date()
        )
        
        do {
            try await taskService.createTask(newTask)
            isLoading = false
            return true
        } catch {
            errorMessage = "Erro ao criar a tarefa. Tente novamente."
            isLoading = false
            return false
        }
    }
}
