
import SwiftUI

@main
struct AppDeMolay: App {
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
                    guard case let .invite(code) = DeepLink(url: url) else { return }
                    authViewModel.pendingInviteCode = code
                }
        }
    }
}
