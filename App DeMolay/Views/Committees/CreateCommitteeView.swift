import SwiftUI

public struct CreateCommitteeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateCommitteeViewModel
    
    enum FocusField { case name }
    @FocusState private var focusedField: FocusField?
    
    public init(chapterId: UUID) {
        _viewModel = State(initialValue: CreateCommitteeViewModel(chapterId: chapterId))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome da Comissão", text: $viewModel.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
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
            .navigationTitle("Nova comissão")
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
                            let success = await viewModel.saveCommittee()
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
                focusedField = .name
                await viewModel.loadMembers()
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
    CreateCommitteeView(chapterId: UUID())
}
