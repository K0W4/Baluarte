import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("CreateCommitteeViewModel Tests")
struct CreateCommitteeViewModelTests {
    
    @Test("Initialization sets default values")
    func testInitialization() {
        let viewModel = CreateCommitteeViewModel()
        
        #expect(viewModel.name == "")
        #expect(viewModel.chairmanId == nil)
        #expect(viewModel.isValid == false)
        #expect(viewModel.selectedMembersIds.isEmpty)
    }
    
    @Test("Validation logic")
    func testValidation() {
        let viewModel = CreateCommitteeViewModel()
        
        viewModel.name = "Committee"
        #expect(viewModel.isValid == false)
        
        viewModel.chairmanId = UUID()
        #expect(viewModel.isValid == true)
    }
    
    @Test("loadMembers fetches members correctly")
    func testLoadMembers() async {
        let mockService = TestMockMemberService()
        mockService.membersToReturn = [
            Member(id: UUID(), chapterId: UUID(), fullName: "John", role: "None", isActive: true, isSenior: false, isMason: false, accessLevel: "member", createdAt: Date()),
            Member(id: UUID(), chapterId: UUID(), fullName: "Jane", role: "None", isActive: false, isSenior: true, isMason: false, accessLevel: "member", createdAt: Date())
        ]
        
        let viewModel = CreateCommitteeViewModel(memberService: mockService)
        await viewModel.loadMembers()
        
        #expect(viewModel.availableMembers.count == 2)
        #expect(mockService.fetchMembersCallCount == 1)
    }
    
    @Test("Filtering members works correctly")
    func testMemberFiltering() async {
        let viewModel = CreateCommitteeViewModel()
        viewModel.availableMembers = [
            Member(id: UUID(), chapterId: UUID(), fullName: "John", role: "None", isActive: true, isSenior: false, isMason: false, accessLevel: "member", createdAt: Date()),
            Member(id: UUID(), chapterId: UUID(), fullName: "Jane", role: "None", isActive: false, isSenior: true, isMason: false, accessLevel: "member", createdAt: Date()),
            Member(id: UUID(), chapterId: UUID(), fullName: "Bob", role: "None", isActive: false, isSenior: false, isMason: true, accessLevel: "member", createdAt: Date())
        ]
        
        viewModel.selectedFilter = .todos
        #expect(viewModel.filteredMembers.count == 3)
        
        viewModel.selectedFilter = .ativos
        #expect(viewModel.filteredMembers.count == 1)
        
        viewModel.selectedFilter = .seniors
        #expect(viewModel.filteredMembers.count == 1)
        
        viewModel.selectedFilter = .macons
        #expect(viewModel.filteredMembers.count == 1)
    }
    
    @Test("toggleMemberSelection updates selected set and unsets chairman if removed")
    func testToggleMemberSelection() {
        let viewModel = CreateCommitteeViewModel()
        let memberId = UUID()
        
        viewModel.toggleMemberSelection(memberId)
        #expect(viewModel.selectedMembersIds.contains(memberId) == true)
        
        viewModel.chairmanId = memberId
        viewModel.toggleMemberSelection(memberId)
        #expect(viewModel.selectedMembersIds.contains(memberId) == false)
        #expect(viewModel.chairmanId == nil)
    }
    
    @Test("saveCommittee succeeds")
    func testSaveCommitteeSuccess() async {
        let mockService = TestMockCommitteeService()
        let viewModel = CreateCommitteeViewModel(committeeService: mockService)
        
        viewModel.name = "Committee"
        viewModel.chairmanId = UUID()
        
        let result = await viewModel.saveCommittee()
        
        #expect(result == true)
        #expect(mockService.createCommitteeCallCount == 1)
    }
}
