import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class HomeViewModel {
    public var events: [Event] = []
    public var goals: [Goal] = []
    public var committees: [Committee] = []
    public var tasks: [ChapterTask] = []

    public var isLoading = false
    public var errorMessage: String?

    private let eventService: EventServiceProtocol
    private let goalService: GoalServiceProtocol
    private let committeeService: CommitteeServiceProtocol
    private let taskService: TaskServiceProtocol

    public let currentUserId = UUID()

    public init(
        eventService: EventServiceProtocol = MockEventService(),
        goalService: GoalServiceProtocol = MockGoalService(),
        committeeService: CommitteeServiceProtocol = MockCommitteeService(),
        taskService: TaskServiceProtocol = MockTaskService()
    ) {
        self.eventService = eventService
        self.goalService = goalService
        self.committeeService = committeeService
        self.taskService = taskService
    }

    public func toggleTaskCompletion(taskId: UUID) async {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let originalState = tasks[index].isCompleted

        withAnimation {
            tasks[index].isCompleted.toggle()
        }

        if tasks[index].isCompleted {
            HapticManager.shared.notification(type: .success)
        } else {
            HapticManager.shared.impact(style: .light)
        }

        do {
            try await taskService.toggleTaskCompletion(taskId: taskId, isCompleted: !originalState)
        } catch {
            withAnimation {
                tasks[index].isCompleted = originalState
            }
        }
    }

    public func confirmAttendance(eventId: UUID) async {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        let originalAttendees = events[index].confirmedAttendees

        var attendees = events[index].confirmedAttendees ?? []
        if attendees.contains(currentUserId) {
            attendees.removeAll { $0 == currentUserId }
            HapticManager.shared.impact(style: .rigid)
        } else {
            attendees.append(currentUserId)
            HapticManager.shared.impact(style: .medium)
        }
        events[index].confirmedAttendees = attendees

        do {
            try await eventService.confirmAttendance(eventId: eventId, userId: currentUserId)
        } catch {
            events[index].confirmedAttendees = originalAttendees
        }
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let mockChapterId = UUID()
            async let fetchedEvents = eventService.fetchEvents(for: mockChapterId)
            async let fetchedGoals = goalService.fetchGoals(for: mockChapterId)
            async let fetchedCommittees = committeeService.fetchCommittees(for: mockChapterId)
            async let fetchedTasks = taskService.fetchTasks(for: currentUserId)

            events = try await fetchedEvents
            goals = try await fetchedGoals
            committees = try await fetchedCommittees
            tasks = try await fetchedTasks
        } catch {
            errorMessage = error.localizedDescription
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }
}
