import SwiftUI

public struct MemberDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MemberDetailViewModel
    @State private var showingDeleteAlert = false
    @State private var showingTransferAlert = false
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
                
                if viewModel.canChangeAccessLevel {
                    Section {
                        Picker("Nível de acesso", selection: Binding(
                            get: { viewModel.accessLevel },
                            set: { level in Task { _ = await viewModel.setAccessLevel(level) } }
                        )) {
                            Text(AccessLevel.member.displayName).tag(AccessLevel.member)
                            Text(AccessLevel.admin.displayName).tag(AccessLevel.admin)
                        }

                        if viewModel.canReceiveOwnership {
                            Button("Transferir posse do Capítulo") {
                                showingTransferAlert = true
                            }
                            .foregroundColor(Theme.textPrimary)
                        }
                    } header: {
                        Text("Acesso")
                    } footer: {
                        Text("Administrador cria e edita eventos, metas, comissões e o roster, e aprova entradas. O cargo acima é descritivo e muda a cada gestão — este nível não muda junto.")
                    }
                    .requires(.manageAdmins)
                }

                if viewModel.canDelete {
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
                    } footer: {
                        Text("Este cadastro foi feito à mão e ainda não pertence a ninguém, então pode ser removido.")
                    }
                    .requires(.manageRoster)
                } else {
                    Section {
                        Label("Cadastro vinculado a uma conta", systemImage: "person.badge.shield.checkmark")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    } footer: {
                        Text("Quem tem conta sai do Capítulo por conta própria, pelo próprio perfil. Apagar o cadastro apagaria junto o histórico de presenças, tarefas e comissões dessa pessoa.")
                    }
                    .requires(.manageRoster)
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
                        .requires(.manageRoster)
                    }
                }
            }
            .alert("Transferir posse?", isPresented: $showingTransferAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Transferir", role: .destructive) {
                    Task {
                        let ok = await viewModel.transferOwnership()
                        if ok {
                            HapticManager.shared.notification(type: .success)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("Esta pessoa passa a ser o Fundador do Capítulo e você vira administrador. Só o novo Fundador poderá devolver a posse.")
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
