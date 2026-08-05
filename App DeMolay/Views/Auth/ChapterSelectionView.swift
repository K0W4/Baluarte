import SwiftUI

struct ChapterSelectionView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ChapterSelectionViewModel()
    @State private var showCreateChapter = false
    @State private var searchText = ""
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Encontre seu Capítulo")
                            .font(Typography.largeTitle)
                            .foregroundColor(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)

                        Text("Para aproveitar o Baluarte, você precisa estar vinculado a um Capítulo.")
                            .font(Typography.body)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    content

                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        showCreateChapter = true
                    }) {
                        Text("Criar novo capítulo")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Spacing.screenEdgePadding)
            }
            .searchable(text: $searchText, prompt: "Buscar Capítulo")
            .task(id: searchText) {
                guard !Task.isCancelled else { return }
                if !searchText.isEmpty {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                }
                await viewModel.searchChapters(query: searchText)
            }
            .sheet(isPresented: $showCreateChapter) {
                CreateChapterView {
                    Task { await viewModel.searchChapters(query: searchText) }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sair") {
                        showSignOutAlert = true
                    }
                    .foregroundColor(Theme.destructive)
                    .accessibilityHint("Encerra a sessão e volta para a tela de acesso")
                }
            }
            .alert("Deseja sair da conta?", isPresented: $showSignOutAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Sair", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
                .tint(Theme.accent)
                .accessibilityLabel("Carregando Capítulos")
            Spacer()
        } else if let errorMessage = viewModel.errorMessage {
            Spacer()
            ErrorBannerView(
                message: errorMessage,
                onRetry: {
                    Task { await viewModel.searchChapters(query: searchText) }
                },
                onDismiss: {
                    withAnimation { viewModel.errorMessage = nil }
                }
            )
            Spacer()
        } else if viewModel.chapters.isEmpty {
            Spacer()
            if searchText.isEmpty {
                EmptyStateCard(cardType: .chapter) {
                    HapticManager.shared.impact(style: .light)
                    showCreateChapter = true
                }
                .padding(.horizontal, Spacing.screenEdgePadding)
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "building.2.crop.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(height: Spacing.heroIconSize)
                        .foregroundColor(Theme.accent)
                        .accessibilityHidden(true)

                    Text("Nenhum Capítulo para “\(searchText)”")
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Revise o termo buscado ou limpe a busca para ver todos.")
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.chapters) { chapter in
                        ChapterCard(chapter: chapter)
                            .onTapGesture { select(chapter) }
                    }
                }
            }
        }
    }

    private func select(_ chapter: Chapter) {
        guard case let .authenticated(_, member) = authViewModel.state, let member else { return }
        HapticManager.shared.impact(style: .light)
        Task {
            let joined = await viewModel.selectChapter(chapter, for: member)
            if joined {
                await authViewModel.checkSession()
            }
        }
    }
}
