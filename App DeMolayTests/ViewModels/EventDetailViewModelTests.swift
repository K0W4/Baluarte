import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("EventDetailViewModel Tests")
struct EventDetailViewModelTests {
    
    let sampleEvent = Event(
        id: UUID(),
        chapterId: UUID(),
        title: "Initial Title",
        scheduledDate: Date(),
        eventType: "Reunião Ritualística",
        notes: "Initial Notes",
        confirmedAttendees: [],
        createdAt: Date()
    )
    
    @Test("Initialization populates fields correctly")
    func testInitialization() {
        let viewModel = EventDetailViewModel(event: sampleEvent)
        
        #expect(viewModel.title == "Initial Title")
        #expect(viewModel.eventType == "Reunião Ritualística")
        #expect(viewModel.notes == "Initial Notes")
        #expect(viewModel.hasChanges == false)
        #expect(viewModel.isValid == true)
        #expect(viewModel.isUserConfirmed == false)
    }
    
    @Test("hasChanges and isValid properties work correctly")
    func testValidationAndChanges() {
        let viewModel = EventDetailViewModel(event: sampleEvent)
        
        viewModel.title = "New Title"
        #expect(viewModel.hasChanges == true)
        #expect(viewModel.isValid == true)
        
        viewModel.title = "   "
        #expect(viewModel.isValid == false)
    }
    
    @Test("saveChanges succeeds and updates internal event")
    func testSaveChangesSuccess() async {
        let mockService = TestMockEventService()
        let viewModel = EventDetailViewModel(event: sampleEvent, eventService: mockService)
        
        viewModel.title = "New Title"
        let result = await viewModel.saveChanges()
        
        #expect(result == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(mockService.updateEventCallCount == 1)
        #expect(viewModel.hasChanges == false) // Should be false because internal event was updated
    }
    
    @Test("saveChanges fails and sets error")
    func testSaveChangesFailure() async {
        let mockService = TestMockEventService()
        mockService.shouldThrowError = true
        let viewModel = EventDetailViewModel(event: sampleEvent, eventService: mockService)
        
        viewModel.title = "New Title"
        let result = await viewModel.saveChanges()
        
        #expect(result == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
    
    @Test("toggleAttendance confirms when not confirmed")
    func testToggleAttendanceConfirm() async {
        let mockService = TestMockEventService()
        let userId = UUID()
        let viewModel = EventDetailViewModel(event: sampleEvent, eventService: mockService, currentUserId: userId)
        
        await viewModel.toggleAttendance()
        
        #expect(mockService.confirmAttendanceCallCount == 1)
        #expect(viewModel.isUserConfirmed == true)
    }
    
    @Test("toggleAttendance removes when already confirmed")
    func testToggleAttendanceRemove() async {
        let mockService = TestMockEventService()
        let userId = UUID()
        var event = sampleEvent
        event.confirmedAttendees = [userId]
        
        let viewModel = EventDetailViewModel(event: event, eventService: mockService, currentUserId: userId)
        
        await viewModel.toggleAttendance()
        
        #expect(mockService.removeAttendanceCallCount == 1)
        #expect(viewModel.isUserConfirmed == false)
    }
    
    @Test("deleteEvent succeeds")
    func testDeleteEventSuccess() async {
        let mockService = TestMockEventService()
        let viewModel = EventDetailViewModel(event: sampleEvent, eventService: mockService)
        
        let result = await viewModel.deleteEvent()
        
        #expect(result == true)
        #expect(mockService.deleteEventCallCount == 1)
    }
    
    @Test("deleteEvent fails and sets error")
    func testDeleteEventFailure() async {
        let mockService = TestMockEventService()
        mockService.shouldThrowError = true
        let viewModel = EventDetailViewModel(event: sampleEvent, eventService: mockService)
        
        let result = await viewModel.deleteEvent()
        
        #expect(result == false)
        #expect(viewModel.errorMessage != nil)
    }
}
