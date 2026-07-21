import SwiftUI

public struct RosterView: View {
    @State private var viewModel = RosterViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filtro", selection: $viewModel.selectedFilter) {
                    ForEach(RosterFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.screenEdgePadding)
                .padding(.vertical, Spacing.sm)
                .background(Theme.backgroundPrimary)
                
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        
                        let members = viewModel.filteredMembers
                        
                        if members.isEmpty && !viewModel.isLoading {
                            EmptyStateCard(cardType: .member)
                        } else {
                            ForEach(members) { member in
                                MemberCard(member: member)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .padding(.vertical, Spacing.md)
                }
                .background(Theme.backgroundPrimary)
            }
            .navigationTitle("Nominata")
            .searchable(text: $viewModel.searchText, prompt: "Buscar membro ou cargo")
            .task {
                await viewModel.loadMembers()
            }
        }
    }
}

#Preview {
    RosterView()
}
