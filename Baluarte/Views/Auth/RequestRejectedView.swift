import SwiftUI

struct RequestRejectedView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var isDismissing = false

    private var chapterName: String {
        authViewModel.rejectedRequestChapter?.name ?? String(localized: "o Capítulo")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.textSecondary)
                        .accessibilityHidden(true)

                    VStack(spacing: Spacing.sm) {
                        Text("Solicitação não aprovada")
                            .font(Typography.title1)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("Sua entrada em **\(chapterName)** não foi aprovada desta vez.")
                            .font(Typography.body)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        if let reason = authViewModel.rejectedRequest?.rejectReason, !reason.isEmpty {
                            Text(reason)
                                .font(Typography.body)
                                .foregroundColor(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                                .padding(.top, Spacing.xs)
                        } else {
                            Text("Quem revisou não deixou um motivo. Falar com a administração do Capítulo costuma resolver rápido.")
                                .font(Typography.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)

                    Spacer()

                    Button(action: acknowledge) {
                        if isDismissing {
                            ProgressView().tint(Theme.textPrimary)
                        } else {
                            Text("Tentar outro Capítulo")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isDismissing)
                    .padding(.horizontal, Spacing.screenEdgePadding)
                }
                .padding(.vertical, Spacing.xl)
            }
            .navigationTitle("Solicitação")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sair") {
                        Task { await authViewModel.signOut() }
                    }
                    .foregroundColor(Theme.destructive)
                }
            }
            .toast(
                isPresented: Binding(
                    get: { authViewModel.errorMessage != nil },
                    set: { if !$0 { authViewModel.errorMessage = nil } }
                ),
                message: authViewModel.errorMessage ?? "",
                style: .error
            )
        }
    }

    private func acknowledge() {
        Task {
            isDismissing = true
            await authViewModel.acknowledgeRejection()
            isDismissing = false
        }
    }
}
