import SwiftUI

public struct TasksView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = TasksViewModel()
    @State private var taskToDelete: ChapterTask?
    @State private var showingCreateTask = false
    @State private var showToast = false

    @State private var isCompletedExpanded = true
    @State private var isIndividualExpanded = true
    @State private var collapsedCommittees: Set<UUID> = []

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Filtro", selection: $viewModel.selectedSegment) {
                        ForEach(TasksFilterSegment.allCases) { segment in
                            Text(segment.displayName).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.backgroundPrimary)

                    if viewModel.displayIndividualTasks.isEmpty && viewModel.displayCommitteeTasks.isEmpty && viewModel.displayCompletedTasks.isEmpty && !viewModel.isLoading {
                        ScrollView {
                            VStack(spacing: Spacing.md) {
                                if let errorMessage = viewModel.errorMessage {
                                    ErrorBannerView(
                                        message: errorMessage,
                                        onRetry: { Task { await viewModel.loadData() } },
                                        onDismiss: { withAnimation { viewModel.errorMessage = nil } }
                                    )
                                }
                                EmptyStateCard(cardType: .task) {
                                    showingCreateTask = true
                                }
                            }
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.top, Spacing.screenEdgePadding)
                        }
                        .scrollIndicators(.hidden)
                        .tint(Theme.accent)
        .refreshable { await viewModel.loadData() }
                    } else {
                        contentList
                            .safeAreaInset(edge: .top, spacing: 0) {
                                let counts = viewModel.progressCounts
                                if counts.total > 0 || viewModel.isLoading {
                                    TaskProgressCard(
                                        title: viewModel.selectedSegment == .minhas ? String(localized: "Meu Progresso") : String(localized: "Progresso Geral"),
                                        completed: counts.completed,
                                        total: counts.total
                                    )
                                    .skeleton(isLoading: viewModel.isLoading)
                                    .padding(.horizontal, Spacing.screenEdgePadding)
                                    .padding(.top, Spacing.sm)
                                    .padding(.bottom, Spacing.sm)
                                    .background(
                                        VStack(spacing: 0) {
                                            Theme.backgroundPrimary
                                                .frame(height: Spacing.sm + 16)
                                            Spacer()
                                        }
                                    )
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
                        showingCreateTask = true
                    }) {
                        Image(systemName: "plus").foregroundColor(Theme.accent)
                    }
                    .accessibilityLabel("Criar nova tarefa")
                }
            }
            .alert("Excluir tarefa", isPresented: Binding(
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
                viewModel.currentMembershipId = authViewModel.currentMembershipId
                viewModel.currentChapterId = authViewModel.currentChapterId
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingCreateTask, onDismiss: {
                Task { await viewModel.loadData() }
            }) {
                if let chapterId = authViewModel.currentChapterId, let currentMembershipId = authViewModel.currentMembershipId {
                    CreateTaskView(
                        chapterId: chapterId,
                        currentMembershipId: currentMembershipId,
                        accessLevel: authViewModel.accessLevel
                    )
                }
            }
            .toast(isPresented: $showToast, message: String(localized: "Tarefa atualizada com sucesso!"))
        }
    }

    @ViewBuilder
    private var contentList: some View {
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

            if !viewModel.displayIndividualTasks.isEmpty {
                Section {
                    if isIndividualExpanded {
                        ForEach(viewModel.displayIndividualTasks) { task in
                            taskRow(for: task)
                        }
                    }
                } header: {
                    collapsibleHeader(title: String(localized: "Tarefas Individuais"), isExpanded: $isIndividualExpanded)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            let sortedCommitteeIds = Array(viewModel.displayCommitteeTasks.keys).sorted(by: { viewModel.committeeName(for: $0) < viewModel.committeeName(for: $1) })

            ForEach(sortedCommitteeIds, id: \.self) { committeeId in
                if let tasks = viewModel.displayCommitteeTasks[committeeId], !tasks.isEmpty {
                    let isCollapsed = collapsedCommittees.contains(committeeId)
                    Section {
                        if !isCollapsed {
                            ForEach(tasks) { task in
                                taskRow(for: task)
                            }
                        }
                    } header: {
                        let title = viewModel.isLoading ? String(localized: "Carregando comissão...") : viewModel.committeeName(for: committeeId)
                        Button(action: {
                            withAnimation {
                                if collapsedCommittees.contains(committeeId) {
                                    collapsedCommittees.remove(committeeId)
                                } else {
                                    collapsedCommittees.insert(committeeId)
                                }
                            }
                        }) {
                            HStack {
                                Text(title)
                                    .font(Typography.headline)
                                Spacer()
                                Image(systemName: !isCollapsed ? "chevron.down" : "chevron.right")
                                    .foregroundColor(Theme.accent)
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

            if !viewModel.displayCompletedTasks.isEmpty {
                Section {
                    if isCompletedExpanded {
                        ForEach(viewModel.displayCompletedTasks) { task in
                            taskRow(for: task)
                        }
                    }
                } header: {
                    collapsibleHeader(title: "Concluídas (\(viewModel.displayCompletedTasks.count))", isExpanded: $isCompletedExpanded)
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
        .tint(Theme.accent)
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
                    .foregroundColor(Theme.accent)
            }
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, Spacing.screenEdgePadding)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
        // A direção do chevron era o único indicador de estado: o VoiceOver anunciava
        // "botão" nos dois, e quem não vê o chevron tocava, a lista mudava de tamanho e
        // nada era dito.
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(isExpanded.wrappedValue ? "expandido" : "recolhido")
        .accessibilityHint(isExpanded.wrappedValue ? "Toca duas vezes para recolher" : "Toca duas vezes para expandir")
    }

    @ViewBuilder
    private func taskRow(for task: ChapterTask) -> some View {
        if viewModel.isLoading {
            TaskCard(task: task) {}
                .skeleton(isLoading: true)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenEdgePadding, bottom: Spacing.md, trailing: Spacing.screenEdgePadding))
        } else {
            TaskCard(task: task) {
                Task {
                    let succeeded = await viewModel.toggleTaskCompletion(task: task)
                    if succeeded && !task.isCompleted {
                        showToast = true
                    }
                }
            }
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

                Text(progress, format: .percent.precision(.fractionLength(0)))
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
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
        // Eram três `Text` soltos e duas cápsulas mudas: o VoiceOver lia fragmentos
        // desconexos e a barra, que é o principal sinal de progresso da tela, não era
        // percebida de forma nenhuma.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(
            String(
                format: String(localized: "%1$lld de %2$lld concluídas, %3$lld por cento"),
                completed, total, Int((progress * 100).rounded())
            )
        )
    }
}

#Preview {
    TasksView()
}
