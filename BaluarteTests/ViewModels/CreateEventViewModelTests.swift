import Testing
import Foundation
@testable import Baluarte

@MainActor
@Suite("CreateEventViewModel Tests")
struct CreateEventViewModelTests {
    
    @Test("Initialization sets default values")
    func testInitialization() {
        let viewModel = CreateEventViewModel(chapterId: UUID())
        
        #expect(viewModel.title == "")
        #expect(viewModel.eventType == "Reunião Ritualística")
        #expect(viewModel.notes == "")
        #expect(viewModel.isValid == false)
    }
    
    @Test("Validation logic")
    func testValidation() {
        let viewModel = CreateEventViewModel(chapterId: UUID())
        
        viewModel.title = "   "
        #expect(viewModel.isValid == false)
        
        viewModel.title = "New Event"
        viewModel.notes = "Some notes"
        #expect(viewModel.isValid == true)
    }
    
    @Test("saveEvent succeeds")
    func testSaveEventSuccess() async {
        let mockService = TestMockEventService()
        let viewModel = CreateEventViewModel(chapterId: UUID(), eventService: mockService)
        
        viewModel.title = "New Event"
        viewModel.notes = "Some notes"
        
        let result = await viewModel.saveEvent()
        
        #expect(result == true)
        #expect(mockService.createEventCallCount == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("saveEvent fails and sets error")
    func testSaveEventFailure() async {
        let mockService = TestMockEventService()
        mockService.shouldThrowError = true
        let viewModel = CreateEventViewModel(chapterId: UUID(), eventService: mockService)
        
        viewModel.title = "New Event"
        viewModel.notes = "Some notes"
        
        let result = await viewModel.saveEvent()
        
        #expect(result == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
}
