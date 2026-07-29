import SwiftUI

public struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateTaskViewModel
    
    enum FocusField { case title }
    @FocusState private var focusedField: FocusField?
    
    public init(chapterId: UUID, currentUserId: UUID) {
        _viewModel = State(initialValue: CreateTaskViewModel(chapterId: chapterId, currentUserId: currentUserId))
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
                            .foregroundColor(.red)
                            .font(Typography.caption1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Nova tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(Theme.accent)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            let success = await viewModel.saveTask()
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.body.bold())
                            .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .task {
                focusedField = .title
                await viewModel.loadCommittees()
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                        ProgressView()
                            .tint(Theme.accent)
                    }
                }
            }
        }
    }
}

#Preview {
    CreateTaskView(chapterId: UUID(), currentUserId: UUID())
}
