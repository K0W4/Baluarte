import SwiftUI

public struct TasksView: View {
    @State private var viewModel = TasksViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.activeTasks.isEmpty && !viewModel.isLoading {
                    ScrollView {
                        EmptyStateCard(cardType: .task)
                            .padding(Spacing.screenEdgePadding)
                    }
                } else {
                    List {
                        if !viewModel.generalTasks.isEmpty {
                            Section {
                                ForEach(viewModel.generalTasks) { task in
                                    TaskRow(task: task) {
                                        Task {
                                            await viewModel.toggleTaskCompletion(task: task)
                                        }
                                    }
                                }
                            } header: {
                                Text("Gerais")
                                    .font(Typography.headline)
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        
                        let committeeGroups = viewModel.committeeTasks
                        ForEach(Array(committeeGroups.keys), id: \.self) { committeeId in
                            if let tasks = committeeGroups[committeeId], !tasks.isEmpty {
                                Section {
                                    ForEach(tasks) { task in
                                        TaskRow(task: task) {
                                            Task {
                                                await viewModel.toggleTaskCompletion(task: task)
                                            }
                                        }
                                    }
                                } header: {
                                    Text(viewModel.committeeName(for: committeeId))
                                        .font(Typography.headline)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Theme.backgroundPrimary)
                }
            }
            .navigationTitle("Tarefas")
            .task {
                await viewModel.loadData()
            }
        }
    }
}

#Preview {
    TasksView()
}
