import SwiftUI

public struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateTaskViewModel
    @State private var showDiscardAlert = false
    
    private var hasUnsavedChanges: Bool {
        !viewModel.title.isEmpty
    }
    
    enum FocusField { case title }
    @FocusState private var focusedField: FocusField?
    
    public init(chapterId: UUID, currentMembershipId: UUID, accessLevel: AccessLevel = .member) {
        _viewModel = State(initialValue: CreateTaskViewModel(
            chapterId: chapterId,
            currentMembershipId: currentMembershipId,
            accessLevel: accessLevel
        ))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título da Tarefa", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                    DatePicker("Prazo", selection: $viewModel.dueDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Informações Básicas")
                }
                
                Section {
                    if viewModel.isFetchingCommittees {
                        ProgressView("Carregando comissões...")
                    } else if !viewModel.committees.isEmpty {
                        Picker("Comissão Responsável", selection: $viewModel.selectedCommitteeId) {
                            Text("Nenhuma").tag(UUID?.none)
                            ForEach(viewModel.committees) { committee in
                                Text(committee.name).tag(Optional(committee.id))
                            }
                        }
                    } else {
                        Text("Nenhuma comissão disponível")
                            .foregroundColor(Theme.textSecondary)
                    }
                } header: {
                    Text("Delegação")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(Theme.destructive)
                            .font(Typography.caption1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Nova tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if hasUnsavedChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(Theme.accent)
                    }
                    .accessibilityLabel("Fechar")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        Task {
                            let success = await viewModel.saveTask()
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.body.bold())
                            .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .accessibilityLabel("Salvar tarefa")
                }
            }
            .task {
                focusedField = .title
                await viewModel.loadCommittees()
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
            .alert("Descartar tarefa?", isPresented: $showDiscardAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Descartar", role: .destructive) { dismiss() }
            } message: {
                Text("Você tem alterações não salvas. Tem certeza que deseja descartar?")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: Spacing.sm) {
                            ProgressView()
                                .tint(Theme.accent)
                            Text("Criando tarefa...")
                                .font(Typography.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(Spacing.lg)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
}

#Preview {
    CreateTaskView(chapterId: UUID(), currentMembershipId: UUID())
}
