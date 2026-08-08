import Testing
import Foundation
@testable import Baluarte

@MainActor
@Suite("GoalDetailViewModel Tests")
struct GoalDetailViewModelTests {
    
    let sampleGoal = Goal(
        id: UUID(),
        chapterId: UUID(),
        title: "Test Goal",
        currentValue: 10.5,
        targetValue: 100.0,
        targetDate: Date(),
        isCompleted: false,
        createdAt: Date()
    )
    
    @Test("Initialization populates fields correctly with formatting")
    func testInitialization() {
        let viewModel = GoalDetailViewModel(goal: sampleGoal)
        
        #expect(viewModel.title == "Test Goal")
        #expect(viewModel.currentValue == "10.5" || viewModel.currentValue == "10,5")
        #expect(viewModel.hasChanges == false)
        #expect(viewModel.isValid == true)
    }
    
    @Test("hasChanges and isValid properties work correctly")
    func testValidationAndChanges() {
        let viewModel = GoalDetailViewModel(goal: sampleGoal)
        
        viewModel.title = "New Title"
        #expect(viewModel.hasChanges == true)
        #expect(viewModel.isValid == true)
        
        viewModel.currentValue = "invalid"
        #expect(viewModel.isValid == false)
        
        viewModel.currentValue = "20,5" // comma support
        #expect(viewModel.isValid == true)
    }
    
    @Test("saveChanges with invalid target value sets error")
    func testSaveChangesNegativeTarget() async {
        let viewModel = GoalDetailViewModel(goal: sampleGoal)
        viewModel.targetValue = "0"
        
        let result = await viewModel.saveChanges()
        
        #expect(result == false)
        #expect(viewModel.errorMessage == "A meta alvo deve ser maior que zero.")
    }
    
    @Test("saveChanges with negative current value sets error")
    func testSaveChangesNegativeCurrent() async {
        let viewModel = GoalDetailViewModel(goal: sampleGoal)
        viewModel.currentValue = "-5"
        
        let result = await viewModel.saveChanges()
        
        #expect(result == false)
        #expect(viewModel.errorMessage == "O valor atual não pode ser negativo.")
    }
    
    @Test("saveChanges succeeds and updates internal goal")
    func testSaveChangesSuccess() async {
        let mockService = TestMockGoalService()
        let viewModel = GoalDetailViewModel(goal: sampleGoal, goalService: mockService)
        
        viewModel.currentValue = "20.5"
        let result = await viewModel.saveChanges()
        
        #expect(result == true)
        #expect(mockService.updateGoalCallCount == 1)
        #expect(viewModel.hasChanges == false)
    }
    
    @Test("deleteGoal succeeds")
    func testDeleteGoalSuccess() async {
        let mockService = TestMockGoalService()
        let viewModel = GoalDetailViewModel(goal: sampleGoal, goalService: mockService)
        
        let result = await viewModel.deleteGoal()
        
        #expect(result == true)
        #expect(mockService.deleteGoalCallCount == 1)
    }
}
