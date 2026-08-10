import SwiftUI

public struct CommitteeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CommitteeDetailViewModel
    @State private var showingDeleteAlert = false
    @State private var showingAddMember = false
    @State private var showingDiscardAlert = false
    @State private var isEditing = false
    
    public init(committee: Committee, chapterId: UUID, currentMembershipId: UUID) {
        self._viewModel = State(initialValue: CommitteeDetailViewModel(committee: committee, chapterId: chapterId, currentMembershipId: currentMembershipId))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome da Comissão", text: $viewModel.name)
                } header: {
                    Text("Informações Básicas")
                }
                .disabled(!isEditing)
                
                Section {
                    if viewModel.isFetchingMembers {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        if viewModel.committeeMembers.isEmpty {
                            Text("Nenhum membro na comissão.")
                                .foregroundColor(Theme.textSecondary)
                                .font(Typography.subheadline)
                        } else {
                            ForEach(viewModel.committeeMembers) { member in
                                let isChairman = viewModel.chairmanId == member.id
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(member.fullName)
                                            .font(Typography.body)
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    if isChairman {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                                .contentShape(Rectangle())
                                .contextMenu {
                                    if isEditing {
                                        Button {
                                            viewModel.chairmanId = isChairman ? nil : member.id
                                        } label: {
                                            Label(
                                                isChairman ? "Remover Presidente" : "Definir como Presidente",
                                                systemImage: "crown"
                                            )
                                        }
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let member = viewModel.committeeMembers[index]
                                    viewModel.removeMember(member.id)
                                }
                            }
                            // Fora do modo de edição não existe botão de salvar, então
                            // remover aqui mudava só o estado local: a pessoa deslizava um
                            // nome, a linha sumia, ela fechava a folha e nada tinha sido
                            // gravado. E sem `.requires`, um membro comum também removia.
                            .deleteDisabled(!isEditing)
                        }
                    }
                } header: {
                    HStack {
                        Text("Membros e Presidente")
                        Spacer()
                        if isEditing {
                            Button {
                                showingAddMember = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(Typography.title2)
                                    .foregroundColor(Theme.accentText)
                                    .frame(minWidth: Spacing.minTouchTarget, minHeight: Spacing.minTouchTarget)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Adicionar membro à comissão")
                            .requires(.manageCommittees)
                        }
                    }
                } footer: {
                    if !viewModel.isFetchingMembers {
                        if isEditing {
                            Text("Toque e segure um membro para defini-lo como Presidente. É obrigatório ter um presidente para salvar.")
                        } else {
                            Text("Toque no lápis para adicionar ou remover membros e trocar o Presidente.")
                        }
                    }
                }
                

                
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Text("Excluir comissão")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                .requires(.manageCommittees)
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(Theme.destructive)
                            .font(Typography.caption1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Detalhes da Comissão")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if isEditing && viewModel.hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accentText)
                    .accessibilityLabel("Fechar")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button(action: {
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
                    } else {
                        Button(action: {
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .requires(.manageCommittees)
                    }
                }
            }
            .alert("Excluir comissão", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { showingDeleteAlert = false }
                Button("Excluir", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteCommittee()
                        if success { dismiss() }
                    }
                }
            } message: {
                Text("Tem certeza que deseja excluir esta comissão? Esta ação não pode ser desfeita.")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .tint(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddMemberToCommitteeView(viewModel: viewModel)
            }
            // A folha se fechava por arrasto e levava junto tudo que tinha sido montado,
            // em silêncio — as telas irmãs de criação já protegiam esse mesmo gesto.
            .interactiveDismissDisabled(isEditing && viewModel.hasChanges)
            .alert("Descartar alterações?", isPresented: $showingDiscardAlert) {
                Button("Continuar editando", role: .cancel) { }
                Button("Descartar", role: .destructive) { dismiss() }
            } message: {
                Text("As mudanças nos membros e no Presidente ainda não foram salvas.")
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}
