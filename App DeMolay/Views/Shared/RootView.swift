import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        Group {
            switch authViewModel.state {
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
                
            case .authenticated(_, let member):
                if let member = member {
                    if member.chapterId == nil {
                        ChapterSelectionView()
                            .transition(.opacity)
                    } else {
                        ContentView()
                            .transition(.opacity)
                    }
                } else {
                    ChapterSelectionView()
                        .transition(.opacity)
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut, value: hasSeenOnboarding)
    }
}

#Preview {
    RootView()
}
