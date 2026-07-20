import SwiftUI

public struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(alignment: .center){
                                Text("Eventos")
                                    .font(Typography.title2)
                                    .bold()
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                Button {
                                    
                                } label: {
                                    Image(systemName: "plus")
                                        .font(Typography.title2)
                                        .bold()
                                        .foregroundColor(.accent)
                                }
                            }

                            if viewModel.events.isEmpty {
                                EmptyStateCard(cardType: .event)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false)
                                {
                                    HStack(spacing: Spacing.md) {
                                        ForEach(viewModel.events) { event in
                                            EventCard(event: event)
                                                .frame(width: 320)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(alignment: .center) {
                                Text("Metas")
                                    .font(Typography.title2)
                                    .bold()
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                Button {
                                    
                                } label: {
                                    Image(systemName: "plus")
                                        .font(Typography.title2)
                                        .bold()
                                        .foregroundColor(.accent)
                                }
                            }
                            
                            if viewModel.goals.isEmpty {
                                EmptyStateCard(cardType: .goal)
                            } else {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                    ],
                                ) {
                                    ForEach(viewModel.goals) { goal in
                                        ProgressRingCard(goal: goal)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(alignment: .center) {
                                Text("Comissões")
                                    .font(Typography.title2)
                                    .bold()
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                Button {
                                    
                                } label: {
                                    Image(systemName: "plus")
                                        .font(Typography.title2)
                                        .bold()
                                        .foregroundColor(.accent)
                                }
                                
                            }
                            if viewModel.committees.isEmpty {
                                EmptyStateCard(cardType: .committee)
                            } else {
                                ForEach(viewModel.committees) { committee in
                                    let committeeTasks = viewModel.tasks.filter
                                    { $0.committeeId == committee.id }
                                    CommitteeCard(
                                        committee: committee,
                                        tasks: committeeTasks
                                    )
                                }
                            }
                        }
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

#Preview {
    HomeView()
}
