import SwiftUI

public struct HomeView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = HomeViewModel()
    @State private var showingCreateEvent = false
    @State private var showingCreateGoal = false
    @State private var showingCreateCommittee = false
    
    @State private var selectedEvent: Event?
    @State private var selectedGoal: Goal?
    @State private var selectedCommittee: Committee?

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text(viewModel.isLoading ? "Carregando resumo..." : "Você tem \(viewModel.tasks.filter { !$0.isCompleted }.count) tarefas pendentes.")
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
                    let displayGoals = viewModel.isLoading ? Goal.skeletonList : viewModel.goals
                    let displayCommittees = viewModel.isLoading ? Committee.skeletonList : viewModel.committees
                    let displayTasks = viewModel.isLoading ? ChapterTask.skeletonList : viewModel.tasks
                    
                    EventsSection(
                        events: displayEvents,
                        isLoading: viewModel.isLoading,
                        currentUserId: viewModel.currentUserId ?? UUID(),
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
                        isLoading: viewModel.isLoading,
                        onCreateGoal: {
                            showingCreateGoal = true
                        },
                        onSelectGoal: { goal in
                            selectedGoal = goal
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
                            .accessibilityLabel("Meu Perfil")
                    }

                }
            }
            .tint(Theme.accent)
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                viewModel.currentUserId = authViewModel.currentUserId
                viewModel.currentChapterId = authViewModel.currentChapterId
                await viewModel.loadData()
            }
            .onAppear {
                viewModel.currentUserId = authViewModel.currentUserId
                viewModel.currentChapterId = authViewModel.currentChapterId
                Task { await viewModel.loadData(showLoading: false) }
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
            .sheet(item: $selectedEvent, onDismiss: {
                Task { await viewModel.loadData() }
            }) { event in
                if let currentUserId = authViewModel.currentUserId {
                    EventDetailView(event: event, currentUserId: currentUserId)
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
                if let currentUserId = authViewModel.currentUserId, let currentChapterId = authViewModel.currentChapterId {
                    CommitteeDetailView(committee: committee, chapterId: currentChapterId, currentUserId: currentUserId)
                }
            }
        }
    }
}

private struct EventsSection: View {
    let events: [Event]
    let isLoading: Bool
    let currentUserId: UUID
    let onConfirmAttendance: (UUID) -> Void
    let onCreateEvent: () -> Void
    let onSelectEvent: (Event) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Eventos",
                actionLabel: "Adicionar evento",
                actionHint: "Toca duas vezes para criar um novo evento"
            ) {
                onCreateEvent()
            }
            .padding(.horizontal, Spacing.screenEdgePadding)

            if events.isEmpty && !isLoading {
                EmptyStateCard(cardType: .event) {
                    onCreateEvent()
                }
                .padding(.horizontal, Spacing.screenEdgePadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(events) { event in
                            let isConfirmed = event.confirmedAttendees?.contains(currentUserId) ?? false
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
    let goals: [Goal]
    let isLoading: Bool
    let onCreateGoal: () -> Void
    let onSelectGoal: (Goal) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Metas",
                actionLabel: "Adicionar meta",
                actionHint: "Toca duas vezes para criar uma nova meta"
            ) {
                onCreateGoal()
            }
            .padding(.horizontal, Spacing.screenEdgePadding)
            
            if goals.isEmpty && !isLoading {
                EmptyStateCard(cardType: .goal) {
                    onCreateGoal()
                }
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
    let committees: [Committee]
    let tasks: [ChapterTask]
    let isLoading: Bool
    let onTaskToggled: (UUID) -> Void
    let onCreateCommittee: () -> Void
    let onSelectCommittee: (Committee) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Comissões",
                actionLabel: "Adicionar comissão",
                actionHint: "Toca duas vezes para criar uma nova comissão"
            ) {
                onCreateCommittee()
            }
            
            if committees.isEmpty && !isLoading {
                EmptyStateCard(cardType: .committee) {
                    onCreateCommittee()
                }
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
