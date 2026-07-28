import Foundation
import SwiftUI

@Observable
@MainActor
public final class CreateCommitteeViewModel {
    public var name: String = ""
    
    public var isLoading: Bool = false
    public var isFetchingMembers: Bool = false
    public var errorMessage: String? = nil
    
    public enum MemberFilter: String, CaseIterable {
        case todos = "Todos"
        case ativos = "Ativos"
        case seniors = "Sêniors"
        case macons = "Maçons"
    }
    
    public var selectedFilter: MemberFilter = .todos
    
    public var filteredMembers: [Member] {
        switch selectedFilter {
        case .todos: return availableMembers
        case .ativos: return availableMembers.filter { $0.isActive }
        case .seniors: return availableMembers.filter { $0.isSenior }
        case .macons: return availableMembers.filter { $0.isMason }
        }
    }
    
    public var availableMembers: [Member] = []
    public var selectedMembersIds: Set<UUID> = []
    public var chairmanId: UUID? = nil
    
    private let committeeService: CommitteeServiceProtocol
    private let memberService: MemberServiceProtocol
    private let chapterId: UUID
    
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        chairmanId != nil
    }
    
    public init(
        chapterId: UUID,
        committeeService: CommitteeServiceProtocol = Services.committee,
        memberService: MemberServiceProtocol = Services.member
    ) {
        self.committeeService = committeeService
        self.memberService = memberService
        self.chapterId = chapterId
    }
    
    public func loadMembers() async {
        isFetchingMembers = true
        do {
            self.availableMembers = try await memberService.fetchMembers(for: chapterId)
            isFetchingMembers = false
        } catch {
            if error is CancellationError { return }
            isFetchingMembers = false
        }
    }
    
    public func toggleMemberSelection(_ memberId: UUID) {
        if selectedMembersIds.contains(memberId) {
            selectedMembersIds.remove(memberId)
            if chairmanId == memberId {
                chairmanId = nil
            }
        } else {
            selectedMembersIds.insert(memberId)
        }
    }
    
    public func saveCommittee() async -> Bool {
        guard isValid else { return false }
        
        isLoading = true
        errorMessage = nil
        
        // Na prática, a tabela de membros da comissão será salva após a criação da comissão.
        let newCommittee = Committee(
            id: UUID(),
            chapterId: chapterId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            chairmanId: chairmanId,
            memberIds: Array(selectedMembersIds),
            createdAt: Date()
        )
        
        do {
            try await committeeService.createCommittee(newCommittee)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = "Erro ao criar a comissão. Tente novamente."
            isLoading = false
            return false
        }
    }
}
