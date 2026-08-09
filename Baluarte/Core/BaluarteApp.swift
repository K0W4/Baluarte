
import SwiftUI

@main
struct BaluarteApp: App {
    @State private var authViewModel = AuthViewModel()
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true

    init() {
        NotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
                .task {
                    if isFirstLaunch {
                        await authViewModel.signOut()
                        isFirstLaunch = false
                    }
                }
                .onOpenURL { url in
                    switch DeepLink(url: url) {
                    case let .invite(code):
                        authViewModel.pendingInviteCode = code
                    case let .passwordRecovery(url):
                        Task { await authViewModel.beginPasswordRecovery(from: url) }
                    case nil:
                        break
                    }
                }
        }
    }
}
