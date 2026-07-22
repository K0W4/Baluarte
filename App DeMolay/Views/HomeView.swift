import SwiftUI

public struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if viewModel.isLoading {
                        ProgressView("Carregando...")
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Spacing.screenEdgePadding)
                    } else {
                        EventsSection(
                            events: viewModel.events,
                            currentUserId: viewModel.currentUserId,
                            onConfirmAttendance: { eventId in
                                viewModel.confirmAttendance(eventId: eventId)
                            }
                        )
                        GoalsSection(goals: viewModel.goals)
                        CommitteesSection(
                            committees: viewModel.committees,
                            tasks: viewModel.tasks,
                            onTaskToggled: { taskId in
                                viewModel.toggleTaskCompletion(taskId: taskId)
                            }
                        )
                            .padding(.horizontal, Spacing.screenEdgePadding)
                    }
                }
                .padding(.top, Spacing.screenEdgePadding)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Olá, Kowa")
            .toolbarTitleDisplayMode(.inlineLarge)
            
            .task {
                await viewModel.loadData()
            }
        }
    }
}

private struct EventsSection: View {
    let events: [Event]
    let currentUserId: UUID
    let onConfirmAttendance: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Eventos",
                actionLabel: "Adicionar evento",
                actionHint: "Toca duas vezes para criar um novo evento"
            ) {
                // Action
            }
            .padding(.horizontal, Spacing.screenEdgePadding)

            if events.isEmpty {
                EmptyStateCard(cardType: .event)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Metas",
                actionLabel: "Adicionar meta",
                actionHint: "Toca duas vezes para criar uma nova meta"
            ) {
                // Action
            }
            .padding(.horizontal, Spacing.screenEdgePadding)
            
            if goals.isEmpty {
                EmptyStateCard(cardType: .goal)
                    .padding(.horizontal, Spacing.screenEdgePadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(goals) { goal in
                            ProgressRingCard(goal: goal)
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
    let committees: [Committee]
    let tasks: [ChapterTask]
    let onTaskToggled: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Comissões",
                actionLabel: "Adicionar comissão",
                actionHint: "Toca duas vezes para criar uma nova comissão"
            ) {
                // Action
            }
            
            if committees.isEmpty {
                EmptyStateCard(cardType: .committee)
            } else {
                ForEach(committees) { committee in
                    let committeeTasks = tasks.filter { $0.committeeId == committee.id }
                    CommitteeCard(
                        committee: committee,
                        tasks: committeeTasks,
                        onTaskToggled: onTaskToggled
                    )
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
