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
                    VStack(spacing: 0) {
                        TasksProgressHeader(
                            completed: viewModel.allTasks.filter { $0.isCompleted }.count,
                            total: viewModel.allTasks.count
                        )
                        
                        List {
                            if !viewModel.generalTasks.isEmpty {
                                TaskSectionView(
                                    title: "Gerais",
                                    tasks: viewModel.generalTasks,
                                    viewModel: viewModel
                                )
                            }
                            
                            let committeeGroups = viewModel.committeeTasks
                            ForEach(Array(committeeGroups.keys), id: \.self) { committeeId in
                                if let tasks = committeeGroups[committeeId], !tasks.isEmpty {
                                    TaskSectionView(
                                        title: viewModel.committeeName(for: committeeId),
                                        tasks: tasks,
                                        viewModel: viewModel
                                    )
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(Theme.backgroundPrimary)
                    }
                }
            }
            .navigationTitle("Tarefas")
            .task {
                await viewModel.loadData()
            }
        }
    }
}

private struct TasksProgressHeader: View {
    let completed: Int
    let total: Int
    
    var body: some View {
        if total > 0 {
            HStack {
                Text("\(completed) de \(total) tarefas concluídas")
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .bold()
                Spacer()
            }
            .padding(.horizontal, Spacing.screenEdgePadding)
            .padding(.top, Spacing.md)
        }
    }
}

private struct TaskSectionView: View {
    let title: String
    let tasks: [ChapterTask]
    let viewModel: TasksViewModel
    
    var body: some View {
        Section {
            ForEach(tasks) { task in
                TaskRow(task: task) {
                    Task {
                        await viewModel.toggleTaskCompletion(task: task)
                    }
                }
            }
        } header: {
            Text(title)
                .font(Typography.headline)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

#Preview {
    TasksView()
}
