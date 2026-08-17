import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            switch authViewModel.route {
            case .loading:
                ZStack {
                    Theme.backgroundPrimary.ignoresSafeArea()
                    ProgressView()
                        .tint(Theme.accent)
                }

            case .unauthenticated:
                if !hasSeenOnboarding {
                    OnboardingView {
                        if reduceMotion {
                            hasSeenOnboarding = true
                        } else {
                            withAnimation { hasSeenOnboarding = true }
                        }
                    }
                } else {
                    LoginView()
                        .transition(.opacity)
                        .accessibilityIdentifier("root.login")
                }

            case .chapterSelection:
                ChapterSelectionView()
                    .transition(.opacity)
                    .accessibilityIdentifier("root.chapterSelection")

            case .pendingApproval:
                PendingApprovalView()
                    .transition(.opacity)
                    .accessibilityIdentifier("root.pendingApproval")

            case .rejected:
                RequestRejectedView()
                    .transition(.opacity)
                    .accessibilityIdentifier("root.rejected")

            case .app:
                ContentView()
                    .transition(.opacity)
                    .accessibilityIdentifier("root.app")
            }
        }
        .animation(reduceMotion ? nil : .easeInOut, value: hasSeenOnboarding)
        .animation(reduceMotion ? nil : .easeInOut, value: authViewModel.route)
        // Sobre qualquer rota: o link de recuperação pode ser aberto por quem está
        // deslogado, dentro do app, ou parado na fila de aprovação.
        .sheet(isPresented: Binding(
            get: { authViewModel.isSettingNewPassword },
            set: { authViewModel.isSettingNewPassword = $0 }
        )) {
            SetNewPasswordView()
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    RootView()
}
