import SwiftUI

struct PendingApprovalView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showCancelAlert = false
    @State private var isRefreshing = false

    private var chapterName: String {
        authViewModel.pendingRequestChapter?.name ?? "seu Capítulo"
    }

    private var requestedAt: String? {
        guard let date = authViewModel.pendingRequest?.createdAt else { return nil }
        return date.formatted(.dateTime.day().month(.wide).hour().minute())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    HeroIcon("hourglass.circle.fill", size: 64)

                    VStack(spacing: Spacing.sm) {
                        Text("Aguardando aprovação")
                            .font(Typography.title1)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("Sua solicitação para entrar no **\(chapterName)** foi enviada. Um administrador do Capítulo precisa aprovar antes de você ver os eventos, metas e tarefas.")
                            .font(Typography.body)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        if let requestedAt {
                            Text("Enviada em \(requestedAt)")
                                .font(Typography.footnote)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.top, Spacing.xxs)
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)

                    Spacer()

                    VStack(spacing: Spacing.sm) {
                        Button(action: refresh) {
                            if isRefreshing {
                                ProgressView().tint(Theme.textPrimary)
                            } else {
                                Text("Já fui aprovado")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isRefreshing)
                        .accessibilityHint("Verifica novamente se a solicitação já foi aprovada")

                        Button("Cancelar solicitação") {
                            showCancelAlert = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)
                }
                .padding(.vertical, Spacing.xl)
            }
            .navigationTitle("Solicitação enviada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sair") {
                        Task { await authViewModel.signOut() }
                    }
                    .foregroundColor(Theme.destructive)
                }
            }
            .alert("Cancelar solicitação?", isPresented: $showCancelAlert) {
                Button("Manter", role: .cancel) { }
                Button("Cancelar solicitação", role: .destructive) {
                    Task { await authViewModel.cancelJoinRequest() }
                }
            } message: {
                Text("Você volta para a busca e pode solicitar entrada em outro Capítulo.")
            }
            .toast(
                isPresented: Binding(
                    get: { authViewModel.errorMessage != nil },
                    set: { if !$0 { authViewModel.errorMessage = nil } }
                ),
                message: authViewModel.errorMessage ?? "",
                style: .error
            )
            .task { await authViewModel.refreshMembershipState() }
        }
    }

    private func refresh() {
        Task {
            isRefreshing = true
            await authViewModel.refreshMembershipState()
            isRefreshing = false
            if authViewModel.activeMembership == nil {
                HapticManager.shared.notification(type: .warning)
            }
        }
    }
}
