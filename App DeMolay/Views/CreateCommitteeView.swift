import SwiftUI

public struct CreateCommitteeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateCommitteeViewModel()
    
    public init() {}
    
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
                        ProgressView("Carregando membros...")
                    } else if !viewModel.availableMembers.isEmpty {
                        Picker("Filtro", selection: $viewModel.selectedFilter) {
                            ForEach(CreateCommitteeViewModel.MemberFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, Spacing.xs)
                        
                        List {
                            ForEach(viewModel.filteredMembers) { member in
                                let isSelected = viewModel.selectedMembersIds.contains(member.id)
                                let isChairman = viewModel.chairmanId == member.id
                                
                                HStack {
                                    Button(action: {
                                        viewModel.toggleMemberSelection(member.id)
                                    }) {
                                        HStack {
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                                            Text(member.fullName)
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Button(action: {
                                            viewModel.chairmanId = isChairman ? nil : member.id
                                        }) {
                                            Image(systemName: isChairman ? "crown.fill" : "crown")
                                                .foregroundColor(isChairman ? Theme.accent : Theme.textSecondary)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(isChairman ? "Remover presidente" : "Definir como presidente")
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Nenhum membro disponível")
                            .foregroundColor(Theme.textSecondary)
                    }
                } header: {
                    HStack {
                        Text("Membros e Presidente")
                        Spacer()
                        if !viewModel.selectedMembersIds.isEmpty {
                            Text("\(viewModel.selectedMembersIds.count) selecionado(s)")
                                .textCase(.none)
                        }
                    }
                } footer: {
                    Text("Selecione os membros da comissão. Clique na coroa para definir o presidente (Obrigatório).")
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
            .navigationTitle("Nova Comissão")
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
                            let success = await viewModel.saveCommittee()
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
                await viewModel.loadMembers()
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
        }
    }
}

#Preview {
    CreateCommitteeView()
}
