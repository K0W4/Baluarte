import SwiftUI

struct RedeemInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var viewModel = RedeemInviteViewModel()
    @FocusState private var isFocused: Bool

    /// Prefilled when the person arrived through a shared link.
    let prefilledCode: String?

    init(prefilledCode: String? = nil) {
        self.prefilledCode = prefilledCode
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)

                        Text("Digite o código do convite")
                            .font(Typography.title2)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("Quem já está no Capítulo pode gerar um código para você. Com ele, você entra direto.")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.lg)

                    TextField("XXXX-XXXX", text: $viewModel.code)
                        .font(.system(.title2, design: .monospaced).weight(.semibold))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .submitLabel(.go)
                        .onSubmit(redeem)
                        .onChange(of: viewModel.code) { _, newValue in
                            viewModel.formatInput(newValue)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                        .accessibilityLabel("Código do convite")

                    Text("O código não usa as letras I, L, O e U nem os números 0 e 1.")
                        .font(Typography.footnote)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button(action: redeem) {
                        if viewModel.isLoading {
                            ProgressView().tint(Theme.textPrimary)
                        } else {
                            Text("Entrar no Capítulo")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.isValid)
                }
                .padding(Spacing.screenEdgePadding)
            }
            .navigationTitle("Convite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityLabel("Fechar")
                }
            }
            .toast(
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                message: viewModel.errorMessage ?? ""
            )
            .task {
                if let prefilledCode {
                    viewModel.formatInput(prefilledCode)
                }
                isFocused = viewModel.code.isEmpty
            }
        }
    }

    private func redeem() {
        Task {
            let membership = await viewModel.redeem()
            if membership != nil {
                HapticManager.shared.notification(type: .success)
                await authViewModel.refreshMembershipState()
                dismiss()
            } else {
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}
