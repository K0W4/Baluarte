import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @ScaledMetric(relativeTo: .headline) private var scaledButtonHeight: CGFloat = 50

    // Acompanha o Dynamic Type, mas com teto para o botão da Apple não dominar a tela.
    private var appleButtonHeight: CGFloat {
        min(scaledButtonHeight, 72)
    }

    private var isLoading: Bool {
        if case .loading = authViewModel.state { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.accent.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    Spacer()

                    VStack(spacing: Spacing.md) {
                        Image("LaunchIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
                            .accessibilityHidden(true)

                        Text("Baluarte")
                            .font(Typography.largeTitle)
                            .foregroundColor(Theme.onAccent)
                            .accessibilityAddTraits(.isHeader)

                        Text("Gestão inteligente para seu Capítulo")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.onAccent)
                    }

                    Spacer()

                    if let errorMessage = authViewModel.errorMessage {
                        ErrorBannerView(
                            message: errorMessage,
                            onRetry: {
                                withAnimation { authViewModel.errorMessage = nil }
                            }
                        )
                        .padding(.horizontal, Spacing.screenEdgePadding)
                    }

                    VStack(spacing: Spacing.md) {
                        if isLoading {
                            ProgressView()
                                .tint(Theme.onAccent)
                                .frame(height: appleButtonHeight)
                                .accessibilityLabel("Entrando")
                        } else {
                            SignInWithAppleButton(.continue) { request in
                                AppleSignInHelper.shared.prepare(request: request)
                            } onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    Task {
                                        do {
                                            let credentials = try AppleSignInHelper.shared.credentials(from: authorization)
                                            await authViewModel.signInWithApple(credentials: credentials)
                                            HapticManager.shared.notification(type: .success)
                                        } catch {
                                            authViewModel.failAppleSignIn(with: error)
                                            HapticManager.shared.notification(type: .error)
                                        }
                                    }
                                case .failure(let error):
                                    guard (error as? ASAuthorizationError)?.code != .canceled else { return }
                                    authViewModel.failAppleSignIn(with: error)
                                    HapticManager.shared.notification(type: .error)
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: appleButtonHeight)
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)

                    HStack {
                        Rectangle().fill(Theme.onAccent.opacity(0.5)).frame(height: 1)
                        Text("ou")
                            .font(Typography.caption1)
                            .foregroundColor(Theme.onAccent)
                        Rectangle().fill(Theme.onAccent.opacity(0.5)).frame(height: 1)
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .accessibilityHidden(true)

                    NavigationLink(destination: EmailAuthView()) {
                        Text("Entrar com E-mail")
                    }
                    .buttonStyle(OnAccentButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticManager.shared.impact(style: .light)
                    })
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .padding(.bottom, Spacing.xl)
                    .accessibilityHint("Abre a tela de acesso por e-mail e senha")
                }
            }
        }
    }
}
