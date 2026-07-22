import SwiftUI

public struct TasksView: View {
    @State private var viewModel = TasksViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                if viewModel.activeTasks.isEmpty && !viewModel.isLoading {
                    ScrollView {
                        EmptyStateCard(cardType: .task)
                            .padding(Spacing.screenEdgePadding)
                    }
                } else {
                    let displayAllTasks = viewModel.isLoading ? ChapterTask.skeletonList : viewModel.allTasks
                    let displayGeneralTasks = viewModel.isLoading ? ChapterTask.skeletonList : viewModel.generalTasks
                    let mockCommitteeId = UUID()
                    let displayCommitteeTasks = viewModel.isLoading ? [mockCommitteeId: ChapterTask.skeletonList] : viewModel.committeeTasks
                    
                    VStack(spacing: 0) {
                        if displayAllTasks.count > 0 {
                            TaskProgressCard(
                                completed: displayAllTasks.filter { $0.isCompleted }.count,
                                total: displayAllTasks.count
                            )
                            .skeleton(isLoading: viewModel.isLoading)
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.top, Spacing.screenEdgePadding)
                            .padding(.bottom, Spacing.sm)
                        }
                        
                        List {
                            if !displayGeneralTasks.isEmpty {
                                Section {
                                    ForEach(displayGeneralTasks) { task in
                                        TaskCard(task: task) {
                                            if !viewModel.isLoading {
                                                Task {
                                                    await viewModel.toggleTaskCompletion(task: task)
                                                }
                                            }
                                        }
                                        .skeleton(isLoading: viewModel.isLoading)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                if !viewModel.isLoading {
                                                    Task {
                                                        await viewModel.deleteTask(task: task)
                                                    }
                                                }
                                            } label: {
                                                Label("Excluir", systemImage: "trash")
                                            }
                                        }
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenEdgePadding, bottom: Spacing.md, trailing: Spacing.screenEdgePadding))
                                    }
                                } header: {
                                    SectionHeaderView(title: "Gerais")
                                        .skeleton(isLoading: viewModel.isLoading)
                                        .padding(.horizontal, Spacing.screenEdgePadding)
                                        .padding(.top, Spacing.sm)
                                        .padding(.bottom, Spacing.md)
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            
                            let sortedCommitteeIds = Array(displayCommitteeTasks.keys).sorted(by: { viewModel.committeeName(for: $0) < viewModel.committeeName(for: $1) })
                            
                            ForEach(sortedCommitteeIds, id: \.self) { committeeId in
                                if let tasks = displayCommitteeTasks[committeeId], !tasks.isEmpty {
                                    Section {
                                        ForEach(tasks) { task in
                                            TaskCard(task: task) {
                                                if !viewModel.isLoading {
                                                    Task {
                                                        await viewModel.toggleTaskCompletion(task: task)
                                                    }
                                                }
                                            }
                                            .skeleton(isLoading: viewModel.isLoading)
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    if !viewModel.isLoading {
                                                        Task {
                                                            await viewModel.deleteTask(task: task)
                                                        }
                                                    }
                                                } label: {
                                                    Label("Excluir", systemImage: "trash")
                                                }
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenEdgePadding, bottom: Spacing.md, trailing: Spacing.screenEdgePadding))
                                        }
                                    } header: {
                                        let title = viewModel.isLoading ? "Carregando comissão..." : viewModel.committeeName(for: committeeId)
                                        SectionHeaderView(title: title)
                                            .skeleton(isLoading: viewModel.isLoading)
                                            .padding(.horizontal, Spacing.screenEdgePadding)
                                            .padding(.top, 0)
                                            .padding(.bottom, Spacing.md)
                                    }
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Tarefas")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}

private struct TaskProgressCard: View {
    let completed: Int
    let total: Int
    
    var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Progresso Geral")
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("\(completed) de \(total) tarefas concluídas")
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(Typography.title1)
                    .foregroundColor(Theme.accent)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 8)
                        .foregroundColor(Theme.textSecondary.opacity(0.2))
                    
                    Capsule()
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                        .foregroundColor(Theme.accent)
                }
            }
            .frame(height: 8)
        }
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

#Preview {
    TasksView()
}
