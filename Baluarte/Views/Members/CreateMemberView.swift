import SwiftUI

public struct CreateMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateMemberViewModel
    @State private var showDiscardAlert = false
    
    private var hasUnsavedChanges: Bool {
        !viewModel.fullName.isEmpty || !viewModel.cid.isEmpty
    }
    
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
                            .foregroundColor(Theme.destructive)
                            .font(Typography.caption1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Novo membro")
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
                            let success = await viewModel.saveMember()
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
                    .accessibilityLabel("Salvar membro")
                }
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
            .alert("Descartar membro?", isPresented: $showDiscardAlert) {
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
                            Text("Adicionando membro...")
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
    CreateMemberView(chapterId: UUID())
}
