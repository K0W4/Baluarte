import Foundation
import SwiftUI

@Observable
@MainActor
public final class CreateCommitteeViewModel {
    public var name: String = ""
    
    public var isLoading: Bool = false
    public var isFetchingMembers: Bool = false
    public var errorMessage: String? = nil
    
    /// Reusa `MembersFilter` em vez de repetir os quatro casos: o enum que existia aqui
    /// carregava os rótulos no próprio `rawValue`, e a View os desenhava com
    /// `Text(filter.rawValue)` — inicializador que **não** localiza, então o segmentado
    /// ficava em português nos três idiomas.
    public var selectedFilter: MembersFilter = .todos
    
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
            // Sem isto, a tela caía no `else` e afirmava "Nenhum membro disponível" — ou
            // seja, dizia que o Capítulo não tem membros quando o que houve foi a rede
            // cair. O administrador concluía que tinha perdido o roster.
            errorMessage = AppError.from(error).userMessage
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
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }
}
