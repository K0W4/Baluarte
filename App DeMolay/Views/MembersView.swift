import SwiftUI

public struct MembersView: View {
    @State private var viewModel = MembersViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filtro", selection: $viewModel.selectedFilter) {
                    ForEach(MembersFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.screenEdgePadding)
                .padding(.vertical, Spacing.sm)
                .background(Theme.backgroundPrimary)
                
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        if viewModel.isLoading {
                            ProgressView("Carregando membros...")
                        } else {
                            let members = viewModel.filteredMembers
                            
                            HStack {
                                Text("\(members.count) membros")
                                    .font(Typography.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                            }
                            
                            if members.isEmpty {
                                EmptyStateCard(cardType: .member)
                            } else {
                                ForEach(members) { member in
                                    MemberCard(member: member)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .padding(.vertical, Spacing.md)
                }
                .background(Theme.backgroundPrimary)
            }
            .navigationTitle("Membros")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Buscar membro ou cargo")
            .task {
                await viewModel.loadMembers()
            }
        }
    }
}

#Preview {
    MembersView()
}
