import SwiftUI

public enum TasksFilterSegment: String, CaseIterable, Identifiable {
    case todas = "Todas as Tarefas"
    case minhas = "Minhas Tarefas"
    public var id: String { rawValue }
}

public struct TasksView: View {
    @State private var viewModel = TasksViewModel()
    @State private var taskToDelete: ChapterTask?
    
    @State private var selectedSegment: TasksFilterSegment = .todas
    
    // Collapsible states
    @State private var isCompletedExpanded = true
    @State private var isIndividualExpanded = true
    @State private var expandedCommittees: Set<UUID> = [] // Will default to expanded when they appear
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Filtro", selection: $selectedSegment) {
                        ForEach(TasksFilterSegment.allCases) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.backgroundPrimary)
                    
                    if viewModel.activeTasks.isEmpty && viewModel.completedTasks.isEmpty && !viewModel.isLoading {
                        ScrollView {
                            VStack(spacing: Spacing.md) {
                                if let errorMessage = viewModel.errorMessage {
                                    ErrorBannerView(
                                        message: errorMessage,
                                        onRetry: { Task { await viewModel.loadData() } },
                                        onDismiss: { withAnimation { viewModel.errorMessage = nil } }
                                    )
                                }
                                EmptyStateCard(cardType: .task)
                            }
                            .padding(Spacing.screenEdgePadding)
                        }
                        .scrollIndicators(.hidden)
                        .refreshable { await viewModel.loadData() }
                    } else {
                        contentList
                            .safeAreaInset(edge: .top, spacing: 0) {
                                let (completedCount, totalCount) = getProgressCounts()
                                if totalCount > 0 || viewModel.isLoading {
                                    TaskProgressCard(
                                        title: selectedSegment == .minhas ? "Meu Progresso" : "Progresso Geral",
                                        completed: completedCount,
                                        total: totalCount
                                    )
                                    .skeleton(isLoading: viewModel.isLoading)
                                    .padding(.horizontal, Spacing.screenEdgePadding)
                                    .padding(.top, Spacing.sm)
                                    .padding(.bottom, Spacing.sm)
                                }
                            }
                    }
                }
            }
            .navigationTitle("Tarefas")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                    }) {
                        Image(systemName: "plus").foregroundColor(Theme.accent)
                    }
                }
            }
            .alert("Excluir Tarefa", isPresented: Binding(
                get: { taskToDelete != nil },
                set: { if !$0 { taskToDelete = nil } }
            )) {
                Button("Cancelar", role: .cancel) { taskToDelete = nil }
                Button("Excluir", role: .destructive) {
                    if let task = taskToDelete {
                        Task { await viewModel.deleteTask(task: task) }
                    }
                    taskToDelete = nil
                }
            } message: {
                if let task = taskToDelete {
                    Text("Tem certeza que deseja excluir \"\(task.title)\"? Esta ação não pode ser desfeita.")
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        let displayIndividualTasks = getDisplayIndividualTasks()
        let displayCommitteeTasks = getDisplayCommitteeTasks()
        let displayCompletedTasks = getCompletedTasks()
        let (_, _) = getProgressCounts()
        
        List {
            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(
                    message: errorMessage,
                    onRetry: { Task { await viewModel.loadData() } },
                    onDismiss: { withAnimation { viewModel.errorMessage = nil } }
                )
                .padding(.horizontal, Spacing.screenEdgePadding)
                .padding(.top, Spacing.sm)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            if !displayIndividualTasks.isEmpty {
                Section {
                    if isIndividualExpanded {
                        ForEach(displayIndividualTasks) { task in
                            taskRow(for: task)
                        }
                    }
                } header: {
                    collapsibleHeader(title: "Tarefas Individuais", isExpanded: $isIndividualExpanded)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            let sortedCommitteeIds = Array(displayCommitteeTasks.keys).sorted(by: { viewModel.committeeName(for: $0) < viewModel.committeeName(for: $1) })
            
            ForEach(sortedCommitteeIds, id: \.self) { committeeId in
                if let tasks = displayCommitteeTasks[committeeId], !tasks.isEmpty {
                    let isExpanded = expandedCommittees.contains(committeeId)
                    Section {
                        if !isExpanded {
                            ForEach(tasks) { task in
                                taskRow(for: task)
                            }
                        }
                    } header: {
                        let title = viewModel.isLoading ? "Carregando comissão..." : viewModel.committeeName(for: committeeId)
                        Button(action: {
                            withAnimation {
                                if expandedCommittees.contains(committeeId) {
                                    expandedCommittees.remove(committeeId)
                                } else {
                                    expandedCommittees.insert(committeeId)
                                }
                            }
                        }) {
                            HStack {
                                Text(title)
                                    .font(Typography.headline)
                                Spacer()
                                Image(systemName: !isExpanded ? "chevron.down" : "chevron.right")
                            }
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.top, Spacing.sm)
                            .padding(.bottom, Spacing.md)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            
            if !displayCompletedTasks.isEmpty {
                Section {
                    if isCompletedExpanded {
                        ForEach(displayCompletedTasks) { task in
                            taskRow(for: task)
                        }
                    }
                } header: {
                    collapsibleHeader(title: "Concluídas (\(displayCompletedTasks.count))", isExpanded: $isCompletedExpanded)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 100, for: .scrollContent)
        .refreshable {
            await viewModel.loadData()
        }
    }
    
    @ViewBuilder
    private func collapsibleHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        Button(action: {
            withAnimation { isExpanded.wrappedValue.toggle() }
        }) {
            HStack {
                Text(title)
                    .font(Typography.headline)
                Spacer()
                Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
            }
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, Spacing.screenEdgePadding)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
    }
    
    @ViewBuilder
    private func taskRow(for task: ChapterTask) -> some View {
        TaskCard(task: task) {
            if !viewModel.isLoading {
                Task { await viewModel.toggleTaskCompletion(task: task) }
            }
        }
        .skeleton(isLoading: viewModel.isLoading)
        .swipeActions(edge: .trailing) {
            Button {
                taskToDelete = task
            } label: {
                Label("Excluir", systemImage: "trash")
            }
            .tint(.red)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenEdgePadding, bottom: Spacing.md, trailing: Spacing.screenEdgePadding))
    }
    
    // MARK: - Helpers
    
    private func getDisplayIndividualTasks() -> [ChapterTask] {
        if selectedSegment == .todas { return [] }
        if viewModel.isLoading { return ChapterTask.skeletonList }
        return viewModel.generalTasks.filter { $0.assigneeId == viewModel.currentUserId }
    }
    
    private func getDisplayCommitteeTasks() -> [UUID: [ChapterTask]] {
        if viewModel.isLoading {
            return [UUID(): ChapterTask.skeletonList]
        }
        if selectedSegment == .todas {
            return viewModel.committeeTasks
        } else {
            var filtered: [UUID: [ChapterTask]] = [:]
            for (k, v) in viewModel.committeeTasks {
                let myTasks = v.filter { $0.assigneeId == viewModel.currentUserId }
                if !myTasks.isEmpty { filtered[k] = myTasks }
            }
            return filtered
        }
    }
    
    private func getCompletedTasks() -> [ChapterTask] {
        if viewModel.isLoading { return [] }
        if selectedSegment == .todas {
            return viewModel.completedTasks
        } else {
            return viewModel.completedTasks.filter { $0.assigneeId == viewModel.currentUserId }
        }
    }
    
    private func getProgressCounts() -> (completed: Int, total: Int) {
        if viewModel.isLoading { return (0, 0) }
        
        let completed = getCompletedTasks().count
        let activeIndividual = getDisplayIndividualTasks().count
        let activeCommittee = getDisplayCommitteeTasks().values.reduce(0) { $0 + $1.count }
        
        return (completed, completed + activeIndividual + activeCommittee)
    }
}

private struct TaskProgressCard: View {
    let title: String
    let completed: Int
    let total: Int
    
    var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("\(completed) de \(total) tarefas concluídas")
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(Typography.title1.bold())
                    .foregroundColor(Theme.textPrimary)
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
        .background(.regularMaterial)
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
