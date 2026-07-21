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
                    } else {
                        EventsSection(events: viewModel.events)
                        GoalsSection(goals: viewModel.goals)
                        CommitteesSection(committees: viewModel.committees, tasks: viewModel.tasks)
                    }
                }
                .padding(.top, Spacing.screenEdgePadding)
                .padding(.horizontal, Spacing.screenEdgePadding)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Olá, Kowa")            
            .task {
                await viewModel.loadData()
            }
        }
    }
}

private struct EventsSection: View {
    let events: [ChapterEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Eventos",
                actionLabel: "Adicionar evento",
                actionHint: "Toca duas vezes para criar um novo evento"
            ) {
                // Action
            }

            if events.isEmpty {
                EmptyStateCard(cardType: .event)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(events) { event in
                            EventCard(event: event)
                                .frame(width: 320)
                        }
                    }
                }
            }
        }
    }
}

private struct GoalsSection: View {
    let goals: [ChapterGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Metas",
                actionLabel: "Adicionar meta",
                actionHint: "Toca duas vezes para criar uma nova meta"
            ) {
                // Action
            }
            
            if goals.isEmpty {
                EmptyStateCard(cardType: .goal)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ],
                ) {
                    ForEach(goals) { goal in
                        ProgressRingCard(goal: goal)
                    }
                }
            }
        }
    }
}

private struct CommitteesSection: View {
    let committees: [Committee]
    let tasks: [ChapterTask]
    
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
                        tasks: committeeTasks
                    )
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
