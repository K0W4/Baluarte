import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("CreateTaskViewModel Tests")
struct CreateTaskViewModelTests {
    
    @Test("Initialization sets default values")
    func testInitialization() {
        let viewModel = CreateTaskViewModel(chapterId: UUID(), currentUserId: UUID())
        
        #expect(viewModel.title == "")

        #expect(viewModel.selectedCommitteeId == nil)
        #expect(viewModel.isValid == false)
        #expect(viewModel.committees.isEmpty)
    }
    
    @Test("Validation logic")
    func testValidation() {
        let viewModel = CreateTaskViewModel(chapterId: UUID(), currentUserId: UUID())
        
        viewModel.title = "   "
        #expect(viewModel.isValid == false)
        
        viewModel.title = "Task Title"
        #expect(viewModel.isValid == true)
    }
    
    @Test("loadCommittees fetches committees")
    func testLoadCommittees() async {
        let mockService = TestMockCommitteeService()
        mockService.committeesToReturn = [
            Committee(id: UUID(), chapterId: UUID(), name: "Committee 1", chairmanId: UUID(), memberIds: [], createdAt: Date())
        ]
        
        let viewModel = CreateTaskViewModel(chapterId: UUID(), currentUserId: UUID(), committeeService: mockService)
        
        await viewModel.loadCommittees()
        
        #expect(viewModel.committees.count == 1)
        #expect(mockService.fetchCommitteesCallCount == 1)
    }
    
    @Test("saveTask succeeds")
    func testSaveTaskSuccess() async {
        let mockService = TestMockTaskService()
        let viewModel = CreateTaskViewModel(chapterId: UUID(), currentUserId: UUID(), taskService: mockService)
        
        viewModel.title = "Task Title"
        
        let result = await viewModel.saveTask()
        
        #expect(result == true)
        #expect(mockService.createTaskCallCount == 1)
    }
    
    @Test("saveTask fails and sets error")
    func testSaveTaskFailure() async {
        let mockService = TestMockTaskService()
        mockService.shouldThrowError = true
        let viewModel = CreateTaskViewModel(chapterId: UUID(), currentUserId: UUID(), taskService: mockService)
        
        viewModel.title = "Task Title"
        
        let result = await viewModel.saveTask()
        
        #expect(result == false)
        #expect(viewModel.errorMessage != nil)
    }
}
