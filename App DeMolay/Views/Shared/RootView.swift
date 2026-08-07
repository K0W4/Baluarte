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
                }

            case .chapterSelection:
                ChapterSelectionView()
                    .transition(.opacity)

            case .pendingApproval:
                PendingApprovalView()
                    .transition(.opacity)

            case .app:
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut, value: hasSeenOnboarding)
        .animation(reduceMotion ? nil : .easeInOut, value: authViewModel.route)
    }
}

#Preview {
    RootView()
}
