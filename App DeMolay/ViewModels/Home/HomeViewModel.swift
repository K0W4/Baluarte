import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class HomeViewModel {
    public var events: [Event] = []
    public var goals: [Goal] = []
    
    public var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    public var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    public var committees: [Committee] = []
    public var tasks: [ChapterTask] = []
    public var currentUser: Member?

    public var greetingTitle: String {
        guard let user = currentUser,
              let firstName = user.fullName.split(separator: " ").first else {
            return "Olá, Irmão!"
        }
        return "Olá, \(firstName)!"
    }

    public var upcomingEvents: [Event] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return events
            .filter { calendar.startOfDay(for: $0.scheduledDate) >= startOfToday }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    public var isLoading = false
    public var errorMessage: String?

    private let eventService: EventServiceProtocol
    private let goalService: GoalServiceProtocol
    private let committeeService: CommitteeServiceProtocol
    private let taskService: TaskServiceProtocol
    private let memberService: MemberServiceProtocol

    public var currentUserId: UUID?
    public var currentChapterId: UUID?

    public init(
        eventService: EventServiceProtocol = Services.event,
        goalService: GoalServiceProtocol = Services.goal,
        committeeService: CommitteeServiceProtocol = Services.committee,
        taskService: TaskServiceProtocol = Services.task,
        memberService: MemberServiceProtocol = Services.member
    ) {
        self.eventService = eventService
        self.goalService = goalService
        self.committeeService = committeeService
        self.taskService = taskService
        self.memberService = memberService
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
            if error is CancellationError { return }
            withAnimation {
                tasks[index].isCompleted = originalState
            }
        }
    }

    public func confirmAttendance(eventId: UUID) async {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        let originalAttendees = events[index].confirmedAttendees

        var attendees = events[index].confirmedAttendees ?? []
        guard let userId = currentUserId else { return }
        let isRemoving = attendees.contains(userId)
        
        if isRemoving {
            attendees.removeAll { $0 == userId }
            HapticManager.shared.impact(style: .rigid)
        } else {
            attendees.append(userId)
            HapticManager.shared.impact(style: .medium)
        }
        events[index].confirmedAttendees = attendees

        do {
            if isRemoving {
                try await eventService.removeAttendance(eventId: eventId, userId: userId)
            } else {
                try await eventService.confirmAttendance(eventId: eventId, userId: userId)
            }
        } catch {
            if error is CancellationError { return }
            events[index].confirmedAttendees = originalAttendees
        }
    }

    public func loadData(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil

        do {
            guard let currentUserId = currentUserId, let currentChapterId = currentChapterId else { return }
            
            async let fetchedEvents = eventService.fetchEvents(for: currentChapterId)
            async let fetchedGoals = goalService.fetchGoals(for: currentChapterId)
            async let fetchedCommittees = committeeService.fetchCommittees(for: currentChapterId)
            async let fetchedTasks = taskService.fetchTasks(forChapter: currentChapterId)
            async let fetchedMembers = memberService.fetchMembers(for: currentChapterId)

            events = try await fetchedEvents
            goals = try await fetchedGoals
            committees = try await fetchedCommittees
            tasks = try await fetchedTasks
            
            let allMembers = try await fetchedMembers
            currentUser = allMembers.first { $0.id == currentUserId }
        } catch {
            // Se falhou por Foreign Key ou qualquer outra coisa do Chapter, vamos tentar recriar o Test Chapter silenciosamente
            if String(describing: error).contains("23503") || String(describing: error).contains("PGRST") || events.isEmpty {
                if let currentChapterId = currentChapterId {
                    let defaultChapter = Chapter(id: currentChapterId, name: "Meu Capítulo", number: 1)
                    _ = try? await Services.chapter.createChapter(defaultChapter)
                }
            }
            
            if error is CancellationError { 
                withAnimation(.easeInOut(duration: 0.3)) { self.isLoading = false }
                return 
            }
            errorMessage = AppError.from(error).userMessage
        }

        if showLoading {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }
}
