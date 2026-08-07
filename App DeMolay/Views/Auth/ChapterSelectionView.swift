import SwiftUI

struct ChapterSelectionView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ChapterSelectionViewModel()
    @State private var showRequestChapter = false
    @State private var searchText = ""
    @State private var showSignOutAlert = false
    @State private var requesting: Chapter?
    @State private var showRedeemInvite = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
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

                    StateFilterRow(selected: $viewModel.selectedUF)

                    content

                    // O convite tem peso visual maior de propósito: é o caminho rápido,
                    // e quem chega com um código não deveria ter que buscar antes.
                    VStack(spacing: Spacing.sm) {
                        Button(action: {
                            HapticManager.shared.impact(style: .light)
                            showRedeemInvite = true
                        }) {
                            Label("Tenho um código de convite", systemImage: "ticket.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button(action: {
                            HapticManager.shared.impact(style: .light)
                            showRequestChapter = true
                        }) {
                            Text("Não encontrei meu Capítulo")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(Spacing.screenEdgePadding)
            }
            .searchable(text: $searchText, prompt: "Nome, número ou cidade")
            .task(id: searchKey) {
                guard !Task.isCancelled else { return }
                if !searchText.isEmpty {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                }
                await viewModel.search(query: searchText)
            }
            .sheet(isPresented: $showRequestChapter) {
                RequestChapterView()
            }
            .sheet(item: $requesting) { chapter in
                RequestToJoinSheet(chapter: chapter)
            }
            .sheet(isPresented: $showRedeemInvite, onDismiss: {
                authViewModel.pendingInviteCode = nil
            }) {
                RedeemInviteView(prefilledCode: authViewModel.pendingInviteCode)
            }
            // Um código que chegou por link abre a folha sozinho — pedir para a pessoa
            // tocar num botão logo depois de ter tocado no link é atrito à toa.
            .onChange(of: authViewModel.pendingInviteCode) { _, newValue in
                if newValue != nil { showRedeemInvite = true }
            }
            .task {
                if authViewModel.pendingInviteCode != nil { showRedeemInvite = true }
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
            .toast(
                isPresented: Binding(
                    get: { authViewModel.errorMessage != nil },
                    set: { if !$0 { authViewModel.errorMessage = nil } }
                ),
                message: authViewModel.errorMessage ?? ""
            )
        }
    }

    /// Re-runs the search when either the text or the state filter changes.
    private var searchKey: String {
        "\(viewModel.selectedUF?.rawValue ?? "")|\(searchText)"
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
                    Task { await viewModel.search(query: searchText) }
                },
                onDismiss: {
                    withAnimation { viewModel.errorMessage = nil }
                }
            )
            Spacer()
        } else if viewModel.chapters.isEmpty {
            Spacer()
            ChapterSearchEmptyState(
                searchText: searchText,
                stateName: viewModel.selectedUF?.name
            )
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
            .scrollIndicators(.hidden)
        }
    }

    private func select(_ chapter: Chapter) {
        HapticManager.shared.impact(style: .light)
        requesting = chapter
    }
}

private struct RequestToJoinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    let chapter: Chapter
    @State private var message = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Capítulo", value: chapter.name)
                    LabeledContent("Número", value: "\(chapter.number)")
                    if let location = chapter.locationLabel {
                        LabeledContent("Onde fica", value: location)
                    }
                } header: {
                    Text("Você está pedindo para entrar em")
                }

                Section {
                    TextField("Ex.: sou o Escrivão desta gestão", text: $message, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Recado para os administradores (opcional)")
                } footer: {
                    Text("Um administrador do Capítulo precisa aprovar sua entrada. Dizer quem você é acelera bastante.")
                }
            }
            .disabled(isSending)
            .navigationTitle("Solicitar entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityLabel("Cancelar")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: send) {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill").font(.body.weight(.semibold))
                        }
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(isSending)
                    .accessibilityLabel("Enviar solicitação")
                }
            }
        }
    }

    private func send() {
        Task {
            isSending = true
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            let sent = await authViewModel.requestToJoin(chapter, message: trimmed.isEmpty ? nil : trimmed)
            isSending = false
            if sent {
                HapticManager.shared.notification(type: .success)
                dismiss()
            } else {
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}

private struct StateFilterRow: View {
    @Binding var selected: BrazilianState?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xs) {
                StateChip(title: "Todos", isSelected: selected == nil) {
                    selected = nil
                }

                ForEach(BrazilianState.allCases) { state in
                    StateChip(title: state.rawValue, isSelected: selected == state) {
                        selected = selected == state ? nil : state
                    }
                    .accessibilityLabel(state.name)
                }
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }
}

private struct StateChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            action()
        }) {
            Text(title)
                .font(Typography.subheadline)
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: Spacing.minTouchTarget)
                .background(isSelected ? Theme.accent : Theme.backgroundTertiary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private struct ChapterSearchEmptyState: View {
    let searchText: String
    let stateName: String?

    private var title: String {
        if searchText.isEmpty {
            if let stateName { return "Nenhum Capítulo em \(stateName)" }
            return "Nenhum Capítulo cadastrado ainda"
        }
        return "Nenhum Capítulo para “\(searchText)”"
    }

    private var subtitle: String {
        if searchText.isEmpty {
            return "O catálogo é montado a partir do registro oficial da Ordem. Se o seu ainda não aparece, solicite o cadastro abaixo."
        }
        return "Revise o termo buscado, troque o estado ou limpe a busca para ver todos."
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "building.2.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(height: Spacing.heroIconSize)
                .foregroundColor(Theme.accent)
                .accessibilityHidden(true)

            Text(title)
                .font(Typography.headline)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
