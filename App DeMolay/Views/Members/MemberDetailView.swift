import SwiftUI

public struct MemberDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MemberDetailViewModel
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    
    public init(member: Member) {
        self._viewModel = State(initialValue: MemberDetailViewModel(member: member))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome Completo", text: $viewModel.fullName)
                    
                    DatePicker("Data de Nascimento", selection: $viewModel.birthdate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                        
                    TextField("ID (Opcional)", text: $viewModel.cid)
                } header: {
                    Text("Dados Pessoais")
                }
                .disabled(!isEditing)
                
                Section {
                    Toggle("Ativo", isOn: $viewModel.isActive)
                        .tint(Theme.accent)
                        .onChange(of: viewModel.isActive) { _, newValue in
                            if newValue {
                                viewModel.isSenior = false
                                viewModel.isMason = false
                                viewModel.updateRoleIfNeeded()
                            }
                        }
                    
                    Toggle("Sênior DeMolay", isOn: $viewModel.isSenior)
                        .tint(Theme.accent)
                        .onChange(of: viewModel.isSenior) { _, newValue in
                            if newValue {
                                viewModel.isActive = false
                                viewModel.updateRoleIfNeeded()
                            }
                        }
                    
                    Toggle("Maçom", isOn: $viewModel.isMason)
                        .tint(Theme.accent)
                        .onChange(of: viewModel.isMason) { _, newValue in
                            if newValue {
                                viewModel.isActive = false
                                viewModel.updateRoleIfNeeded()
                            }
                        }
                } header: {
                    Text("Status")
                }
                .disabled(!isEditing)
                
                Section {
                    Picker("Cargo", selection: $viewModel.role) {
                        ForEach(viewModel.roles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                } header: {
                    Text("Atuação no Capítulo")
                }
                .disabled(!isEditing)
                
                Section {
                    Button(action: {
                        HapticManager.shared.notification(type: .warning)
                        showingDeleteAlert = true
                    }) {
                        Text("Excluir membro")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
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
            .navigationTitle("Detalhes do Membro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .accessibilityLabel("Fechar")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button(action: {
                            HapticManager.shared.impact(style: .medium)
                            Task {
                                let success = await viewModel.saveChanges()
                                if success { isEditing = false }
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                        }
                        .font(.body.bold())
                        .foregroundColor(viewModel.isValid && viewModel.hasChanges ? Theme.accent : Theme.textSecondary.opacity(0.5))
                        .disabled(!viewModel.isValid || !viewModel.hasChanges || viewModel.isLoading)
                        .accessibilityLabel("Salvar alterações")
                    } else {
                        Button(action: {
                            HapticManager.shared.impact(style: .light)
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .accessibilityLabel("Editar")
                    }
                }
            }
            .alert("Excluir membro", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { showingDeleteAlert = false }
                Button("Excluir", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteMember()
                        if success { dismiss() }
                    }
                }
            } message: {
                Text("Tem certeza que deseja excluir este membro? Esta ação não pode ser desfeita.")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: Spacing.sm) {
                            ProgressView()
                                .tint(Theme.accent)
                            Text("Salvando...")
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
