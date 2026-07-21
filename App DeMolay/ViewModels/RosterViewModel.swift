import Foundation
import Observation

public enum RosterFilter: String, CaseIterable, Identifiable {
    case todos = "Todos"
    case ativos = "Ativos"
    case seniors = "Sêniors"
    case macons = "Maçons"
    
    public var id: String { self.rawValue }
}

@Observable
public final class RosterViewModel {
    public var allMembers: [Member] = []
    public var searchText: String = ""
    public var selectedFilter: RosterFilter = .todos
    
    public var isLoading = false
    public var errorMessage: String?
    
    public var committees: [Committee] = []
    public var tasks: [ChapterTask] = []
    
    private let memberService: MemberServiceProtocol
    
    public init(memberService: MemberServiceProtocol = MockMemberService()) {
        self.memberService = memberService
    }
    
    @MainActor
    public func loadMembers() async {
        isLoading = true
        errorMessage = nil
        do {
            let mockChapterId = UUID()
            allMembers = try await memberService.fetchMembers(for: mockChapterId)
            
            let mockCommitteeId1 = UUID()
            let mockCommitteeId2 = UUID()
            committees = [
                Committee(id: mockCommitteeId1, chapterId: mockChapterId, name: "Sindicância", chairmanId: nil, createdAt: Date()),
                Committee(id: mockCommitteeId2, chapterId: mockChapterId, name: "Hospitalaria", chairmanId: nil, createdAt: Date())
            ]
            tasks = [
                ChapterTask(id: UUID(), chapterId: mockChapterId, creatorId: UUID(), committeeId: mockCommitteeId1, title: "Entrevistar fulano", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400), createdAt: Date()),
                ChapterTask(id: UUID(), chapterId: mockChapterId, creatorId: UUID(), committeeId: mockCommitteeId1, title: "Votar em plenário", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(-86400), createdAt: Date())
            ]
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public var filteredMembers: [Member] {
        var result = allMembers
        
        switch selectedFilter {
        case .todos:
            break
        case .ativos:
            result = result.filter { $0.isActive }
        case .seniors:
            result = result.filter { $0.isSenior }
        case .macons:
            result = result.filter { $0.isMason }
        }
        
        if !searchText.isEmpty {
            result = result.filter { member in
                member.fullName.localizedCaseInsensitiveContains(searchText) ||
                (member.role?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        result.sort { $0.fullName < $1.fullName }
        
        return result
    }
}
