import SwiftUI

struct AnalysisView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = AnalysisViewModel()
    @State private var showingCreateEvent = false
    @State private var showingCreateCommittee = false
    @State private var showingMembers = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "apple.intelligence")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.accent)
                                .accessibilityLabel("Inteligência Apple")
                            
                            Text("Painel Estratégico")
                                .font(Typography.title2)
                            
                            Text("Análises geradas por Apple Intelligence")
                                .font(Typography.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.top, Spacing.xl)
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(Theme.destructive)
                                .padding()
                                .frame(height: 300)
                        } else {
                            let displayGrouped: [(key: AnalysisCategory, value: [DisplayedAnalysis])] = viewModel.isLoading ? [
                                (key: .membership, value: [DisplayedAnalysis.skeletonList[0], DisplayedAnalysis.skeletonList[1], DisplayedAnalysis.skeletonList[2]]),
                                (key: .structure, value: [DisplayedAnalysis.skeletonList[3], DisplayedAnalysis.skeletonList[4], DisplayedAnalysis.skeletonList[5]])
                            ] : viewModel.groupedAnalyses

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
                                .frame(height: 300)
                            } else {
                                VStack(spacing: Spacing.xl) {
                                    ForEach(displayGrouped, id: \.key) { group in
                                        VStack(alignment: .leading, spacing: Spacing.md) {
                                            SectionHeaderView(title: titleFor(category: group.key))
                                                .padding(.horizontal, Spacing.screenEdgePadding)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: Spacing.xs) {
                                                    ForEach(group.value) { analysis in
                                                        AnalysisCard(analysis: analysis) {
                                                            handleAction(for: analysis.category)
                                                        }
                                                        .containerRelativeFrame(.horizontal)
                                                    }
                                                }
                                                .fixedSize(horizontal: false, vertical: true)
                                                .scrollTargetLayout()
                                            }
                                            .contentMargins(.horizontal, Spacing.screenEdgePadding, for: .scrollContent)
                                            .scrollTargetBehavior(.viewAligned)
                                        }
                                        .skeleton(isLoading: viewModel.isLoading)
                                    }
                                }
                                .padding(.bottom, 100)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Análise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            if let chapterId = authViewModel.currentChapterId {
                                await viewModel.fetchAnalyses(chapterId: chapterId)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
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
    
    private func handleAction(for category: AnalysisCategory) {
        switch category {
        case .membership:
            showingMembers = true
        case .structure:
            showingCreateCommittee = true
        case .calendar:
            showingCreateEvent = true
        default:
            break
        }
    }
    
    private func titleFor(category: AnalysisCategory) -> String {
        switch category {
        case .membership: return "Membros e Iniciação"
        case .structure: return "Estrutura e Comissões"
        case .calendar: return "Calendário e Eventos"
        case .engagement: return "Engajamento e Frequência"
        case .financial: return "Planejamento Financeiro"
        }
    }
}
