import SwiftUI

public struct CommitteeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CommitteeDetailViewModel
    @State private var showingDeleteAlert = false
    @State private var showingAddMember = false
    
    public init(committee: Committee, chapterId: UUID, currentUserId: UUID) {
        self._viewModel = State(initialValue: CommitteeDetailViewModel(committee: committee, chapterId: chapterId, currentUserId: currentUserId))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome da Comissão", text: $viewModel.name)
                } header: {
                    Text("Informações Básicas")
                }
                
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
                                    Button {
                                        viewModel.chairmanId = isChairman ? nil : member.id
                                    } label: {
                                        Label {
                                            Text(isChairman ? "Remover Presidente" : "Definir como Presidente")
                                                .foregroundColor(Theme.textPrimary)
                                        } icon: {
                                            Image(systemName: "crown")
                                                .foregroundColor(Theme.accent)
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
                        }
                    }
                } header: {
                    HStack {
                        Text("Membros e Presidente")
                        Spacer()
                        Button {
                            showingAddMember = true
                        } label: {
                            Image(systemName: "plus")
                                .font(Typography.title2)
                                .foregroundColor(Theme.accent)
                                .padding(.trailing, 0) // Ensures it doesn't push too far left
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    if !viewModel.isFetchingMembers {
                        Text("Pressione e segure um membro selecionado para defini-lo como Presidente (ícone da coroa).")
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
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
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
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            let success = await viewModel.saveChanges()
                            if success { dismiss() }
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                    .font(.body.bold())
                    .foregroundColor(viewModel.isValid && viewModel.hasChanges ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    .disabled(!viewModel.isValid || !viewModel.hasChanges || viewModel.isLoading)
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
        }
        .task {
            await viewModel.loadData()
        }
    }
}
