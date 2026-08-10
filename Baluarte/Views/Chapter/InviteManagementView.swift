import SwiftUI

struct InviteManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var viewModel: InviteManagementViewModel
    @State private var showCreateSheet = false

    private let chapterName: String

    init(chapterId: UUID, chapterName: String) {
        _viewModel = State(initialValue: InviteManagementViewModel(chapterId: chapterId))
        self.chapterName = chapterName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(Theme.accent)
                } else if viewModel.invites.isEmpty {
                    NoInvitesState { showCreateSheet = true }
                        .padding(Spacing.screenEdgePadding)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            if !viewModel.activeInvites.isEmpty {
                                SectionHeaderView(title: "Ativos", actionIcon: nil)
                                ForEach(viewModel.activeInvites) { invite in
                                    InviteCard(
                                        invite: invite,
                                        shareText: viewModel.shareText(for: invite, chapterName: chapterName),
                                        onRevoke: { Task { await viewModel.revoke(invite) } }
                                    )
                                }
                            }

                            if !viewModel.inactiveInvites.isEmpty {
                                SectionHeaderView(title: "Encerrados", actionIcon: nil)
                                ForEach(viewModel.inactiveInvites) { invite in
                                    InviteCard(invite: invite, shareText: nil, onRevoke: nil)
                                }
                            }
                        }
                        .padding(Spacing.screenEdgePadding)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Convites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .accessibilityLabel("Fechar")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus").font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .accessibilityLabel("Gerar novo convite")
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showCreateSheet) {
                CreateInviteSheet(viewModel: viewModel)
            }
            .toast(
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                message: viewModel.errorMessage ?? "",
                style: .error
            )
        }
    }
}

private struct NoInvitesState: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "ticket")
                .resizable()
                .scaledToFit()
                .frame(height: Spacing.heroIconSize)
                .foregroundColor(Theme.accent)
                .accessibilityHidden(true)

            Text("Nenhum convite gerado")
                .font(Typography.headline)
                .foregroundColor(Theme.textPrimary)

            Text("Gere um código e mande no grupo do Capítulo. Quem abrir entra direto, sem passar pela fila de aprovação.")
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Gerar convite", action: onCreate)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, Spacing.xs)
        }
    }
}

private struct InviteCard: View {
    let invite: ChapterInvite
    let shareText: String?
    let onRevoke: (() -> Void)?

    @State private var showRevokeAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(invite.formattedCode)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundColor(invite.isUsable ? Theme.textPrimary : Theme.textSecondary)
                    .accessibilityLabel("Código \(invite.formattedCode.map { String($0) }.joined(separator: " "))")

                Spacer()

                Text(statusLabel)
                    .font(Typography.caption2)
                    .foregroundColor(invite.isUsable ? Theme.accent : Theme.textSecondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Theme.backgroundTertiary)
                    .clipShape(Capsule())
            }

            Text(detail)
                .font(Typography.footnote)
                .foregroundColor(Theme.textSecondary)

            if invite.isUsable, let shareText, let onRevoke {
                HStack(spacing: Spacing.sm) {
                    ShareLink(item: shareText) {
                        Label("Compartilhar", systemImage: "square.and.arrow.up")
                            .font(Typography.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.accent)
                    .frame(minHeight: Spacing.minTouchTarget)

                    Spacer()

                    Button("Revogar") { showRevokeAlert = true }
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.destructive)
                        .frame(minHeight: Spacing.minTouchTarget)
                }
                .alert("Revogar convite?", isPresented: $showRevokeAlert) {
                    Button("Manter", role: .cancel) { }
                    Button("Revogar", role: .destructive) { onRevoke() }
                } message: {
                    Text("Quem ainda não usou este código deixa de conseguir entrar por ele. Quem já entrou continua no Capítulo.")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    private var statusLabel: String {
        if invite.isRevoked { return String(localized: "Revogado") }
        if invite.isExpired { return String(localized: "Expirado") }
        if invite.isExhausted { return String(localized: "Esgotado") }
        return "Ativo"
    }

    private var detail: String {
        var parts: [String] = []

        if let maxUses = invite.maxUses {
            parts.append("\(invite.usesCount) de \(maxUses) usos")
        } else {
            parts.append(invite.usesCount == 1 ? String(localized: "1 uso") : "\(invite.usesCount) usos")
        }

        if let expiresAt = invite.expiresAt {
            let prefix = invite.isExpired ? String(localized: "expirou em") : String(localized: "vale até")
            parts.append("\(prefix) \(expiresAt.formatted(.dateTime.day().month(.abbreviated)))")
        } else {
            parts.append("sem prazo")
        }

        return parts.joined(separator: " · ")
    }
}

private struct CreateInviteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    @Bindable var viewModel: InviteManagementViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Validade", selection: $viewModel.validity) {
                        ForEach(InviteManagementViewModel.Validity.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } header: {
                    Text("Por quanto tempo vale")
                } footer: {
                    Text("Um código com prazo curto é mais seguro: se ele vazar do grupo, para de funcionar sozinho.")
                }

                Section {
                    Toggle("Limitar número de usos", isOn: $viewModel.limitUses)

                    if viewModel.limitUses {
                        Stepper(
                            "Até \(viewModel.maxUses) pessoas",
                            value: $viewModel.maxUses,
                            in: 1...200
                        )
                    }
                } header: {
                    Text("Quantas pessoas podem usar")
                }
            }
            .disabled(viewModel.isCreating)
            .navigationTitle("Gerar convite")
            // O `.toast` da tela de trás desenha num ZStack da hierarquia dela, coberto
            // por esta folha: a pessoa tocava no visto, o telefone vibrava, a folha não
            // fechava, e a mensagem traduzida do servidor nunca era lida.
            .toast(
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                message: viewModel.errorMessage ?? "",
                style: .error
            )
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
                    Button(action: create) {
                        if viewModel.isCreating {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark").font(.body.weight(.semibold))
                        }
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(viewModel.isCreating)
                    .accessibilityLabel("Gerar")
                }
            }
        }
    }

    private func create() {
        guard let userId = authViewModel.currentUserId else { return }
        Task {
            let invite = await viewModel.create(createdBy: userId)
            if invite != nil {
                HapticManager.shared.notification(type: .success)
                dismiss()
            } else {
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}
