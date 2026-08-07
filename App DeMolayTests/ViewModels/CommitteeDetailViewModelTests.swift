import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("CommitteeDetailViewModel Tests")
struct CommitteeDetailViewModelTests {
    
    let sampleCommittee = Committee(
        id: UUID(),
        chapterId: UUID(),
        name: "Initial Committee",
        chairmanId: UUID(),
        memberIds: [UUID(), UUID()],
        createdAt: Date()
    )
    
    @Test("Initialization populates fields correctly")
    func testInitialization() {
        let viewModel = CommitteeDetailViewModel(committee: sampleCommittee, chapterId: UUID(), currentMembershipId: UUID())
        
        #expect(viewModel.name == "Initial Committee")
        #expect(viewModel.chairmanId == sampleCommittee.chairmanId)
        #expect(viewModel.selectedMembersIds.count == 2)
        #expect(viewModel.hasChanges == false)
        #expect(viewModel.isValid == true)
    }
    
    @Test("hasChanges and isValid properties work correctly")
    func testValidationAndChanges() {
        let viewModel = CommitteeDetailViewModel(committee: sampleCommittee, chapterId: UUID(), currentMembershipId: UUID())
        
        viewModel.name = "New Name"
        #expect(viewModel.hasChanges == true)
        #expect(viewModel.isValid == true)
        
        viewModel.name = "   "
        #expect(viewModel.isValid == false)
        
        viewModel.name = "Valid Name"
        viewModel.chairmanId = nil
        #expect(viewModel.isValid == false)
    }
    
    @Test("removeMember and addMember update sets correctly")
    func testMemberManagement() {
        let viewModel = CommitteeDetailViewModel(committee: sampleCommittee, chapterId: UUID(), currentMembershipId: UUID())
        let memberToRemove = sampleCommittee.memberIds![0]
        
        viewModel.removeMember(memberToRemove)
        #expect(viewModel.selectedMembersIds.contains(memberToRemove) == false)
        #expect(viewModel.hasChanges == true)
        
        let newMember = UUID()
        viewModel.addMember(newMember)
        #expect(viewModel.selectedMembersIds.contains(newMember) == true)
    }
    
    @Test("removeMember removes chairman if chairman is removed")
    func testRemoveChairman() {
        let viewModel = CommitteeDetailViewModel(committee: sampleCommittee, chapterId: UUID(), currentMembershipId: UUID())
        let chairmanId = sampleCommittee.chairmanId!
        
        viewModel.removeMember(chairmanId)
        #expect(viewModel.selectedMembersIds.contains(chairmanId) == false)
        #expect(viewModel.chairmanId == nil)
        #expect(viewModel.isValid == false) // Chairman is required
    }
    
    @Test("loadData success populates tasks and members")
    func testLoadDataSuccess() async {
        let memberService = TestMockMemberService()
        let taskService = TestMockTaskService()
        
        memberService.membersToReturn = [
            Member(id: sampleCommittee.memberIds![0], chapterId: UUID(), fullName: "John", role: "None", isActive: true, isSenior: false, isMason: false, accessLevel: "member", createdAt: Date()),
            Member(id: sampleCommittee.memberIds![1], chapterId: UUID(), fullName: "Doe", role: "None", isActive: true, isSenior: false, isMason: false, accessLevel: "member", createdAt: Date())
        ]
        
        taskService.tasksToReturn = [
            ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: sampleCommittee.id, title: "Task 1", description: "Desc", isCompleted: false, createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), committeeId: UUID(), title: "Task 2", description: "Desc", isCompleted: false, createdAt: Date())
        ]
        
        let viewModel = CommitteeDetailViewModel(
            committee: sampleCommittee,
            chapterId: UUID(),
            currentMembershipId: UUID(),
            memberService: memberService,
            taskService: taskService
        )
        
        await viewModel.loadData()
        
        #expect(viewModel.availableMembers.count == 2)
        #expect(viewModel.committeeTasks.count == 1) // Only one belongs to this committee
        #expect(viewModel.committeeMembers.count == 2)
    }
    
    @Test("saveChanges succeeds and updates internal committee")
    func testSaveChangesSuccess() async {
        let mockService = TestMockCommitteeService()
        let viewModel = CommitteeDetailViewModel(committee: sampleCommittee, chapterId: UUID(), currentMembershipId: UUID(), committeeService: mockService)
        
        viewModel.name = "New Name"
        let result = await viewModel.saveChanges()
        
        #expect(result == true)
        #expect(mockService.updateCommitteeCallCount == 1)
        #expect(viewModel.hasChanges == false)
    }
    
    @Test("deleteCommittee succeeds")
    func testDeleteCommitteeSuccess() async {
        let mockService = TestMockCommitteeService()
        let viewModel = CommitteeDetailViewModel(committee: sampleCommittee, chapterId: UUID(), currentMembershipId: UUID(), committeeService: mockService)
        
        let result = await viewModel.deleteCommittee()
        
        #expect(result == true)
        #expect(mockService.deleteCommitteeCallCount == 1)
    }
    
    @Test("toggleTaskCompletion rollback on failure")
    func testToggleTaskCompletionFailure() async {
        let taskService = TestMockTaskService()
        let viewModel = CommitteeDetailViewModel(
            committee: sampleCommittee,
            chapterId: UUID(),
            currentMembershipId: UUID(),
            taskService: taskService
        )
        
        let taskId = UUID()
        viewModel.committeeTasks = [
            ChapterTask(id: taskId, chapterId: UUID(), creatorId: UUID(), title: "Task", description: "Desc", isCompleted: false, createdAt: Date())
        ]
        
        taskService.shouldThrowError = true
        await viewModel.toggleTaskCompletion(taskId: taskId)
        
        #expect(viewModel.committeeTasks[0].isCompleted == false)
        #expect(viewModel.errorMessage != nil)
    }
}
