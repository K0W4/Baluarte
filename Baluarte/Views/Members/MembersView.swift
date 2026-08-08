import SwiftUI

public struct MembersView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.permissions) private var permissions
    @State private var viewModel = MembersViewModel()
    @State private var showingCreateMember = false
    @State private var selectedMember: Member?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filtro", selection: $viewModel.selectedFilter) {
                    ForEach(MembersFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.screenEdgePadding)
                .padding(.vertical, Spacing.sm)
                .background(Theme.backgroundPrimary)
                
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        if let errorMessage = viewModel.errorMessage {
                            ErrorBannerView(
                                message: errorMessage,
                                onRetry: {
                                    Task { await viewModel.loadMembers() }
                                },
                                onDismiss: {
                                    withAnimation { viewModel.errorMessage = nil }
                                }
                            )
                        }
                        
                        let members = viewModel.isLoading ? Member.skeletonList : viewModel.filteredMembers
                        
                        HStack {
                            Text(viewModel.selectedFilter == .todos ? "\(members.count) membros" : "\(members.count) de \(viewModel.allMembers.count) membros")
                                .font(Typography.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .skeleton(isLoading: viewModel.isLoading)
                            Spacer()
                        }
                        
                        if members.isEmpty && !viewModel.isLoading {
                            EmptyStateCard(
                                cardType: .member,
                                action: permissions.can(.manageRoster) ? { showingCreateMember = true } : nil
                            )
                        } else {
                            ForEach(members) { member in
                                MemberCard(member: member)
                                    .skeleton(isLoading: viewModel.isLoading)
                                    .onTapGesture {
                                        selectedMember = member
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .padding(.vertical, Spacing.md)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, 100, for: .scrollContent)
                .background(Theme.backgroundPrimary)
                .tint(Theme.accent)
        .refreshable {
                    await viewModel.loadMembers()
                }
            }
            .navigationTitle("Membros")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        showingCreateMember = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.accent)
                    }
                    .accessibilityLabel("Adicionar novo membro")
                    .requires(.manageRoster)
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Buscar membro ou cargo")
            .task {
                viewModel.currentChapterId = authViewModel.currentChapterId
                await viewModel.loadMembers()
            }
            .sheet(isPresented: $showingCreateMember, onDismiss: {
                Task { await viewModel.loadMembers() }
            }) {
                if let chapterId = authViewModel.currentChapterId {
                    CreateMemberView(chapterId: chapterId)
                }
            }
            .sheet(item: $selectedMember, onDismiss: {
                Task { await viewModel.loadMembers() }
            }) { member in
                MemberDetailView(member: member)
            }
        }
    }
}

#Preview {
    MembersView()
}
