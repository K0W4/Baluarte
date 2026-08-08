import SwiftUI

public struct HomeView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = HomeViewModel()
    @State private var showingCreateEvent = false
    @State private var showingCreateGoal = false
    @State private var showingCreateCommittee = false
    @State private var showingCompletedGoals = false
    
    @State private var selectedEvent: Event?
    @State private var selectedGoal: Goal?
    @State private var selectedCommittee: Committee?
    
    private var hasIncompleteProfile: Bool {
        if case let .authenticated(_, member) = authViewModel.state, let member = member {
            return member.cid == nil || member.birthdate == nil || member.cid?.isEmpty == true
        }
        return false
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text(viewModel.isLoading ? "Carregando resumo..." : (hasIncompleteProfile ? "Você tem informações pendentes no seu perfil." : "Você tem \(viewModel.tasks.filter { !$0.isCompleted }.count) tarefas pendentes."))
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, Spacing.screenEdgePadding)
                        .padding(.top, -Spacing.sm)
                        .skeleton(isLoading: viewModel.isLoading)
                        
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(
                            message: errorMessage,
                            onRetry: {
                                Task { await viewModel.loadData() }
                            },
                            onDismiss: {
                                withAnimation { viewModel.errorMessage = nil }
                            }
                        )
                        .padding(.horizontal, Spacing.screenEdgePadding)
                    }
                    
                    let displayEvents = viewModel.isLoading ? Event.skeletonList : viewModel.upcomingEvents
                    let displayGoals = viewModel.isLoading ? Goal.skeletonList : viewModel.activeGoals
                    let completedGoals = viewModel.completedGoals
                    let displayCommittees = viewModel.isLoading ? Committee.skeletonList : viewModel.committees
                    let displayTasks = viewModel.isLoading ? ChapterTask.skeletonList : viewModel.tasks
                    
                    EventsSection(
                        events: displayEvents,
                        isLoading: viewModel.isLoading,
                        currentMembershipId: viewModel.currentMembershipId ?? UUID(),
                        onConfirmAttendance: { eventId in
                            if !viewModel.isLoading {
                                Task { await viewModel.confirmAttendance(eventId: eventId) }
                            }
                        },
                        onCreateEvent: {
                            showingCreateEvent = true
                        },
                        onSelectEvent: { event in
                            selectedEvent = event
                        }
                    )
                    .skeleton(isLoading: viewModel.isLoading)
                    
                    GoalsSection(
                        goals: displayGoals,
                        hasCompletedGoals: !completedGoals.isEmpty,
                        isLoading: viewModel.isLoading,
                        onCreateGoal: {
                            showingCreateGoal = true
                        },
                        onSelectGoal: { goal in
                            selectedGoal = goal
                        },
                        onViewCompletedGoals: {
                            showingCompletedGoals = true
                        }
                    )
                        .skeleton(isLoading: viewModel.isLoading)
                        
                    CommitteesSection(
                        committees: displayCommittees,
                        tasks: displayTasks,
                        isLoading: viewModel.isLoading,
                        onTaskToggled: { taskId in
                            if !viewModel.isLoading {
                                Task { await viewModel.toggleTaskCompletion(taskId: taskId) }
                            }
                        },
                        onCreateCommittee: {
                            showingCreateCommittee = true
                        },
                        onSelectCommittee: { committee in
                            selectedCommittee = committee
                        }
                    )
                    .skeleton(isLoading: viewModel.isLoading)
                    .padding(.horizontal, Spacing.screenEdgePadding)
                }
                .padding(.top, Spacing.screenEdgePadding)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 100, for: .scrollContent)
            .background(Theme.backgroundPrimary)
            .navigationTitle(viewModel.greetingTitle)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.fill")
                            .foregroundColor(Theme.accent)
                            .accessibilityLabel("Meu perfil")
                    }

                }
            }
            .tint(Theme.accent)
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                viewModel.currentMembershipId = authViewModel.currentMembershipId
                viewModel.currentChapterId = authViewModel.currentChapterId
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingCreateEvent, onDismiss: {
                Task { await viewModel.loadData() }
            }) {
                if let chapterId = authViewModel.currentChapterId {
                    CreateEventView(chapterId: chapterId)
                }
            }
            .sheet(isPresented: $showingCreateGoal, onDismiss: {
                Task { await viewModel.loadData() }
            }) {
                if let chapterId = authViewModel.currentChapterId {
                    CreateGoalView(chapterId: chapterId)
                }
            }
            .sheet(isPresented: $showingCreateCommittee, onDismiss: {
                Task { await viewModel.loadData() }
            }) {
                if let chapterId = authViewModel.currentChapterId {
                    CreateCommitteeView(chapterId: chapterId)
                }
            }
            .sheet(isPresented: $showingCompletedGoals) {
                CompletedGoalsView(viewModel: viewModel)
            }
            .sheet(item: $selectedEvent, onDismiss: {
                Task { await viewModel.loadData() }
            }) { event in
                if let currentMembershipId = authViewModel.currentMembershipId {
                    EventDetailView(event: event, currentMembershipId: currentMembershipId)
                }
            }
            .sheet(item: $selectedGoal, onDismiss: {
                Task { await viewModel.loadData() }
            }) { goal in
                GoalDetailView(goal: goal)
            }
            .sheet(item: $selectedCommittee, onDismiss: {
                Task { await viewModel.loadData() }
            }) { committee in
                if let currentMembershipId = authViewModel.currentMembershipId, let currentChapterId = authViewModel.currentChapterId {
                    CommitteeDetailView(committee: committee, chapterId: currentChapterId, currentMembershipId: currentMembershipId)
                }
            }
        }
    }
}

private struct EventsSection: View {
    @Environment(\.permissions) private var permissions
    let events: [Event]
    let isLoading: Bool
    let currentMembershipId: UUID
    let onConfirmAttendance: (UUID) -> Void
    let onCreateEvent: () -> Void
    let onSelectEvent: (Event) -> Void

    private var createAction: (() -> Void)? {
        permissions.can(.manageEvents) ? onCreateEvent : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Eventos",
                actionLabel: "Adicionar evento",
                actionHint: "Toca duas vezes para criar um novo evento",
                action: createAction
            )
            .padding(.horizontal, Spacing.screenEdgePadding)

            if events.isEmpty && !isLoading {
                EmptyStateCard(cardType: .event, action: createAction)
                .padding(.horizontal, Spacing.screenEdgePadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(events) { event in
                            let isConfirmed = event.confirmedAttendees?.contains(currentMembershipId) ?? false
                            EventCard(event: event, isUserConfirmed: isConfirmed) {
                                onConfirmAttendance(event.id)
                            }
                            .containerRelativeFrame(.horizontal)
                            .onTapGesture {
                                onSelectEvent(event)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, Spacing.screenEdgePadding, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }
}

private struct GoalsSection: View {
    @Environment(\.permissions) private var permissions
    let goals: [Goal]
    let hasCompletedGoals: Bool
    let isLoading: Bool
    let onCreateGoal: () -> Void
    let onSelectGoal: (Goal) -> Void
    let onViewCompletedGoals: () -> Void

    private var createAction: (() -> Void)? {
        permissions.can(.manageGoals) ? onCreateGoal : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Metas",
                actionLabel: "Adicionar meta",
                actionHint: "Toca duas vezes para criar uma nova meta",
                action: createAction
            )
            .padding(.horizontal, Spacing.screenEdgePadding)

            if goals.isEmpty && !hasCompletedGoals && !isLoading {
                EmptyStateCard(cardType: .goal, action: createAction)
                .padding(.horizontal, Spacing.screenEdgePadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(goals) { goal in
                            ProgressRingCard(goal: goal)
                                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: Spacing.xs)
                                .onTapGesture {
                                    onSelectGoal(goal)
                                }
                        }
                        
                        if hasCompletedGoals {
                            Button {
                                onViewCompletedGoals()
                            } label: {
                                VStack(spacing: Spacing.lg) {
                                    ZStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 120, weight: .light))
                                            .foregroundColor(Theme.success)
                                    }
                                    .frame(width: 120, height: 120)
                                    
                                    VStack(spacing: Spacing.xxs) {
                                        Text("Concluídas")
                                            .font(Typography.headline)
                                            .foregroundColor(Theme.textPrimary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .frame(height: 48, alignment: .center)
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.bottom, Spacing.md)
                                .padding(.top, Spacing.xl)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(CardButtonStyle())
                            .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: Spacing.xs)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, Spacing.screenEdgePadding, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }
}

private struct CommitteesSection: View {
    @Environment(\.permissions) private var permissions
    let committees: [Committee]
    let tasks: [ChapterTask]
    let isLoading: Bool
    let onTaskToggled: (UUID) -> Void
    let onCreateCommittee: () -> Void
    let onSelectCommittee: (Committee) -> Void

    private var createAction: (() -> Void)? {
        permissions.can(.manageCommittees) ? onCreateCommittee : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Comissões",
                actionLabel: "Adicionar comissão",
                actionHint: "Toca duas vezes para criar uma nova comissão",
                action: createAction
            )

            if committees.isEmpty && !isLoading {
                EmptyStateCard(cardType: .committee, action: createAction)
            } else {
                ForEach(committees) { committee in
                    let committeeTasks = tasks.filter { $0.committeeId == committee.id }
                    CommitteeCard(
                        committee: committee,
                        tasks: committeeTasks,
                        onTaskToggled: onTaskToggled
                    )
                    .onTapGesture {
                        onSelectCommittee(committee)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
