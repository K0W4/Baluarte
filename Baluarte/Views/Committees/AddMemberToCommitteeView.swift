import SwiftUI

public struct AddMemberToCommitteeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CommitteeDetailViewModel
    
    @State private var searchText = ""
    
    public var body: some View {
        NavigationStack {
            List {
                let availableToAdd = viewModel.availableMembers.filter { !viewModel.selectedMembersIds.contains($0.id) }
                
                let filtered = searchText.isEmpty ? availableToAdd : availableToAdd.filter {
                    $0.fullName.localizedCaseInsensitiveContains(searchText)
                }
                
                if filtered.isEmpty {
                    Text("\(String(localized: "Nenhum membro disponível")).")
                        .foregroundColor(Theme.textSecondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filtered) { member in
                        Button(action: {
                            viewModel.addMember(member.id)
                            dismiss()
                        }) {
                            HStack {
                                Text(member.fullName)
                                    .font(Typography.body)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Buscar membro")
            .navigationTitle("Adicionar membro")
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
            }
        }
    }
}
