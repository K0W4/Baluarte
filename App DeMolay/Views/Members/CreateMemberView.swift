import SwiftUI

public struct CreateMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateMemberViewModel
    
    enum FocusField { case fullName, cid }
    @FocusState private var focusedField: FocusField?
    
    public init(chapterId: UUID) {
        _viewModel = State(initialValue: CreateMemberViewModel(chapterId: chapterId))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome Completo", text: $viewModel.fullName)
                        .focused($focusedField, equals: .fullName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .cid }
                        .textContentType(.name)
                    
                    TextField("ID (Opcional)", text: $viewModel.cid)
                        .focused($focusedField, equals: .cid)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.cid) { oldValue, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered.count > 7 {
                                viewModel.cid = String(filtered.prefix(7))
                            } else if viewModel.cid != filtered {
                                viewModel.cid = filtered
                            }
                        }
                    
                    DatePicker("Data de Nascimento", selection: $viewModel.birthdate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Dados Pessoais")
                }
                
                Section {
                    Picker("Cargo", selection: $viewModel.role) {
                        ForEach(viewModel.roles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    
                    Toggle("Ativo", isOn: $viewModel.isActive)
                        .tint(Theme.accent)
                        .onChange(of: viewModel.isActive) { _, newValue in
                            if newValue {
                                viewModel.isSenior = false
                                viewModel.isMason = false
                            }
                            viewModel.updateRoleIfNeeded()
                        }
                    Toggle("Sênior", isOn: $viewModel.isSenior)
                        .tint(Theme.accent)
                        .onChange(of: viewModel.isSenior) { _, newValue in
                            if newValue {
                                viewModel.isActive = false
                            }
                            viewModel.updateRoleIfNeeded()
                        }
                    Toggle("Maçom", isOn: $viewModel.isMason)
                        .tint(Theme.accent)
                        .onChange(of: viewModel.isMason) { _, newValue in
                            if newValue {
                                viewModel.isActive = false
                            }
                            viewModel.updateRoleIfNeeded()
                        }
                } header: {
                    Text("Status e Cargo")
                } footer: {
                    Text("Obrigatório selecionar pelo menos um status. 'Ativo' não pode ser marcado simultaneamente com 'Sênior' ou 'Maçom'.")
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
            .navigationTitle("Novo membro")
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
                            let success = await viewModel.saveMember()
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
    CreateMemberView(chapterId: UUID())
}
