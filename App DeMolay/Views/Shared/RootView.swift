import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
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
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }
                } else {
                    LoginView()
                        .transition(.opacity)
                }
                
            case .authenticated(_, let member):
                if let member = member {
                    if member.cid == nil || member.birthdate == nil {
                        CompleteProfileView()
                            .transition(.opacity)
                    } else if member.chapterId == nil {
                        ChapterSelectionView()
                            .transition(.opacity)
                    } else {
                        ContentView()
                            .transition(.opacity)
                    }
                } else {
                    CompleteProfileView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut, value: hasSeenOnboarding)
    }
}

#Preview {
    RootView()
}
