import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("CreateGoalViewModel Tests")
struct CreateGoalViewModelTests {
    
    @Test("Initialization sets default values")
    func testInitialization() {
        let viewModel = CreateGoalViewModel(chapterId: UUID())
        
        #expect(viewModel.title == "")

        #expect(viewModel.targetValue == "")
        #expect(viewModel.isValid == false)
    }
    
    @Test("Validation logic works correctly")
    func testValidation() {
        let viewModel = CreateGoalViewModel(chapterId: UUID())
        
        viewModel.title = "New Goal"
        viewModel.targetValue = "invalid"
        #expect(viewModel.isValid == false)
        
        viewModel.targetValue = "10.5"
        #expect(viewModel.isValid == true)
        
        viewModel.targetValue = "10,5"
        #expect(viewModel.isValid == true)
    }
    
    @Test("saveGoal with zero or negative target sets error")
    func testSaveGoalInvalidTarget() async {
        let viewModel = CreateGoalViewModel(chapterId: UUID())
        viewModel.title = "Goal"
        viewModel.targetValue = "0"
        
        let result = await viewModel.saveGoal()
        
        #expect(result == false)
        #expect(viewModel.errorMessage == "A meta alvo deve ser maior que zero.")
    }
    
    @Test("saveGoal succeeds")
    func testSaveGoalSuccess() async {
        let mockService = TestMockGoalService()
        let viewModel = CreateGoalViewModel(chapterId: UUID(), goalService: mockService)
        
        viewModel.title = "New Goal"
        viewModel.targetValue = "100.0"
        
        let result = await viewModel.saveGoal()
        
        #expect(result == true)
        #expect(mockService.createGoalCallCount == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
}
