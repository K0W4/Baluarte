import SwiftUI

public struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateTaskViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título da Tarefa", text: $viewModel.title)
                } header: {
                    Text("Informações Básicas")
                }
                
                Section {
                    TextField("Descrição", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                        
                    DatePicker("Prazo Limite", selection: $viewModel.dueDate, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Detalhes e Prazo")
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
            .navigationTitle("Nova Tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        Task {
                            let success = await viewModel.saveTask()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .font(.body.bold())
                    .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadCommittees()
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .padding()
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

#Preview {
    CreateTaskView()
}
