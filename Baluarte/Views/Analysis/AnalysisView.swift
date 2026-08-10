import SwiftUI

struct AnalysisView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.permissions) private var permissions
    @State private var viewModel = AnalysisViewModel()
    @State private var showingCreateEvent = false
    @State private var showingCreateCommittee = false
    @State private var showingMembers = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        Text("Insights detalhados sobre o seu Capítulo")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.top, Spacing.xs)
                        
                        if let chapterId = authViewModel.currentChapterId {
                            SmartSummaryCard(chapterId: chapterId)
                                .padding(.horizontal, Spacing.screenEdgePadding)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(Theme.destructive)
                                .padding()
                                .frame(minHeight: 300)
                        } else {
                            let displayGrouped: [(key: AnalysisCategory, value: [ConsolidatedInsight])] = viewModel.isLoading ? [
                                (key: .membership, value: [ConsolidatedInsight(category: .membership, severity: .info, items: [DisplayedAnalysis.skeletonList[0]], primaryActionLabel: nil)]),
                                (key: .structure, value: [ConsolidatedInsight(category: .structure, severity: .info, items: [DisplayedAnalysis.skeletonList[3]], primaryActionLabel: nil)])
                            ] : viewModel.consolidatedGroupedAnalyses

                            if displayGrouped.isEmpty && !viewModel.isLoading {
                                VStack(spacing: Spacing.sm) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(Typography.largeTitle)
                                        .foregroundColor(Theme.success)
                                    Text("Tudo em ordem!")
                                        .font(Typography.headline)
                                    Text("Seu Capítulo está cumprindo todas as diretrizes no momento.")
                                        .font(Typography.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(Spacing.xl)
                                .frame(minHeight: 300)
                            } else {
                                VStack(spacing: Spacing.md) {
                                    ForEach(displayGrouped, id: \.key) { group in
                                        if let insight = group.value.first {
                                            InsightSectionCard(
                                                insight: insight,
                                                onActionTapped: action(for: group.key)
                                            )
                                            .padding(.horizontal, Spacing.screenEdgePadding)
                                            .skeleton(isLoading: viewModel.isLoading)
                                        }
                                    }
                                }
                                .padding(.bottom, 100)
                            }
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                }
            }
            .navigationTitle("Análise")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                if let chapterId = authViewModel.currentChapterId {
                    await viewModel.fetchAnalyses(chapterId: chapterId)
                }
            }
            .task {
                if viewModel.displayedAnalyses.isEmpty, let chapterId = authViewModel.currentChapterId {
                    await viewModel.fetchAnalyses(chapterId: chapterId)
                }
            }
            .sheet(isPresented: $showingCreateEvent, onDismiss: {
                Task { 
                    if let chapterId = authViewModel.currentChapterId {
                        await viewModel.fetchAnalyses(chapterId: chapterId)
                    }
                }
            }) {
                if let chapterId = authViewModel.currentChapterId {
                    CreateEventView(chapterId: chapterId)
                }
            }
            .sheet(isPresented: $showingCreateCommittee, onDismiss: {
                Task { 
                    if let chapterId = authViewModel.currentChapterId {
                        await viewModel.fetchAnalyses(chapterId: chapterId)
                    }
                }
            }) {
                if let chapterId = authViewModel.currentChapterId {
                    CreateCommitteeView(chapterId: chapterId)
                }
            }
            .sheet(isPresented: $showingMembers) {
                MembersView()
            }
        }
    }
    
    /// Returns nil when the person cannot perform the suggested action, so the card
    /// renders the insight without a button they would only be denied on.
    private func action(for category: AnalysisCategory) -> (() -> Void)? {
        switch category {
        case .membership:
            return { showingMembers = true }
        case .structure:
            guard permissions.can(.manageCommittees) else { return nil }
            return { showingCreateCommittee = true }
        case .calendar:
            guard permissions.can(.manageEvents) else { return nil }
            return { showingCreateEvent = true }
        default:
            return nil
        }
    }
    

}
