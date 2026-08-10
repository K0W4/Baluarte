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
            return String(localized: "Olá, Irmão!")
        }
        return String(format: String(localized: "Olá, %@!"), String(firstName))
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

    public var currentMembershipId: UUID?
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
            // Reverter sem dizer nada faz a pessoa acreditar que marcou. O háptico de
            // sucesso já foi disparado acima; sem este par, a falha é indistinguível de
            // um toque que não pegou.
            HapticManager.shared.notification(type: .error)
            errorMessage = AppError.from(error).userMessage
        }
    }

    public func confirmAttendance(eventId: UUID) async {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        let originalAttendees = events[index].confirmedAttendees

        var attendees = events[index].confirmedAttendees ?? []
        guard let userId = currentMembershipId else { return }
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
            HapticManager.shared.notification(type: .error)
            errorMessage = AppError.from(error).userMessage
        }
    }

    public func loadData(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil

        // O `isLoading` precisa cair por qualquer saída. Antes, o `guard` abaixo saía da
        // função inteira antes de chegar no `isLoading = false` lá embaixo, e a primeira
        // tela depois do login ficava em esqueleto para sempre — sem conteúdo, sem
        // mensagem e sem botão, inclusive ao puxar para atualizar.
        defer { if showLoading { isLoading = false } }

        do {
            guard let currentMembershipId = currentMembershipId, let currentChapterId = currentChapterId else {
                errorMessage = String(localized: "Não foi possível identificar seu Capítulo. Puxe para atualizar.")
                return
            }

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
            currentUser = allMembers.first { $0.id == currentMembershipId }
        } catch {
            if error is CancellationError { return }
            errorMessage = AppError.from(error).userMessage
        }
    }
}
