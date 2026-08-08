import Testing
import Foundation
@testable import Baluarte

@MainActor
@Suite("HomeViewModel Tests")
struct HomeViewModelTests {
    
    @Test("Initial state is empty and not loading")
    func testInitialState() {
        let viewModel = HomeViewModel(
            eventService: TestMockEventService(),
            goalService: TestMockGoalService(),
            committeeService: TestMockCommitteeService(),
            taskService: TestMockTaskService(),
            memberService: TestMockMemberService()
        )
        
        #expect(viewModel.events.isEmpty)
        #expect(viewModel.goals.isEmpty)
        #expect(viewModel.committees.isEmpty)
        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("loadData updates state correctly on success")
    func testLoadDataSuccess() async {
        let eventService = TestMockEventService()
        let taskService = TestMockTaskService()
        
        eventService.eventsToReturn = [
            Event(id: UUID(), chapterId: UUID(), title: "Event 1", scheduledDate: Date(), eventType: "Type", createdAt: Date())
        ]
        taskService.tasksToReturn = [
            ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Task 1", description: "Desc", isCompleted: false, createdAt: Date())
        ]
        
        let viewModel = HomeViewModel(
            eventService: eventService,
            goalService: TestMockGoalService(),
            committeeService: TestMockCommitteeService(),
            taskService: taskService,
            memberService: TestMockMemberService()
        )
        viewModel.currentMembershipId = UUID()
        viewModel.currentChapterId = UUID()
        
        await viewModel.loadData()
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.events.count == 1)
        #expect(viewModel.tasks.count == 1)
        
        #expect(eventService.fetchEventsCallCount == 1)
        #expect(taskService.fetchTasksCallCount == 1)
    }
    
    @Test("loadData sets error message on failure")
    func testLoadDataFailure() async {
        let eventService = TestMockEventService()
        eventService.shouldThrowError = true
        
        let viewModel = HomeViewModel(
            eventService: eventService,
            goalService: TestMockGoalService(),
            committeeService: TestMockCommitteeService(),
            taskService: TestMockTaskService(),
            memberService: TestMockMemberService()
        )
        viewModel.currentMembershipId = UUID()
        viewModel.currentChapterId = UUID()
        
        await viewModel.loadData()
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.events.isEmpty)
    }
    
    @Test("toggleTaskCompletion performs optimistic update and rollback on failure")
    func testToggleTaskCompletionFailure() async {
        let taskService = TestMockTaskService()
        let taskId = UUID()
        taskService.tasksToReturn = [
            ChapterTask(id: taskId, chapterId: UUID(), creatorId: UUID(), title: "Task 1", description: "Desc", isCompleted: false, createdAt: Date())
        ]
        
        let viewModel = HomeViewModel(
            eventService: TestMockEventService(),
            goalService: TestMockGoalService(),
            committeeService: TestMockCommitteeService(),
            taskService: taskService,
            memberService: TestMockMemberService()
        )
        viewModel.currentMembershipId = UUID()
        viewModel.currentChapterId = UUID()
        
        await viewModel.loadData()
        
        taskService.shouldThrowError = true
        
        #expect(viewModel.tasks.first?.isCompleted == false)
        
        await viewModel.toggleTaskCompletion(taskId: taskId)
        
        #expect(taskService.toggleTaskCompletionCallCount == 1)
        
        #expect(viewModel.tasks.first?.isCompleted == false)
    }
    
    @Test("toggleTaskCompletion performs optimistic update and keeps state on success")
    func testToggleTaskCompletionSuccess() async {
        let taskService = TestMockTaskService()
        let taskId = UUID()
        taskService.tasksToReturn = [
            ChapterTask(id: taskId, chapterId: UUID(), creatorId: UUID(), title: "Task 1", description: "Desc", isCompleted: false, createdAt: Date())
        ]
        
        let viewModel = HomeViewModel(
            eventService: TestMockEventService(),
            goalService: TestMockGoalService(),
            committeeService: TestMockCommitteeService(),
            taskService: taskService,
            memberService: TestMockMemberService()
        )
        viewModel.currentMembershipId = UUID()
        viewModel.currentChapterId = UUID()
        
        await viewModel.loadData()
        
        await viewModel.toggleTaskCompletion(taskId: taskId)
        
        #expect(taskService.toggleTaskCompletionCallCount == 1)
        
        #expect(viewModel.tasks.first?.isCompleted == true)
    }
    
    @Test("confirmAttendance performs optimistic update and rollback on failure")
    func testConfirmAttendanceFailure() async {
        let eventService = TestMockEventService()
        let eventId = UUID()
        eventService.eventsToReturn = [
            Event(id: eventId, chapterId: UUID(), title: "Event 1", scheduledDate: Date(), eventType: "Type", confirmedAttendees: [], createdAt: Date())
        ]
        
        let viewModel = HomeViewModel(
            eventService: eventService,
            goalService: TestMockGoalService(),
            committeeService: TestMockCommitteeService(),
            taskService: TestMockTaskService(),
            memberService: TestMockMemberService()
        )
        viewModel.currentMembershipId = UUID()
        viewModel.currentChapterId = UUID()
        
        await viewModel.loadData()
        eventService.shouldThrowError = true
        
        #expect(viewModel.events.first?.confirmedAttendees?.contains(viewModel.currentMembershipId ?? UUID()) == false)
        
        await viewModel.confirmAttendance(eventId: eventId)
        
        #expect(eventService.confirmAttendanceCallCount == 1)
        
        #expect(viewModel.events.first?.confirmedAttendees?.contains(viewModel.currentMembershipId ?? UUID()) == false)
    }
}
