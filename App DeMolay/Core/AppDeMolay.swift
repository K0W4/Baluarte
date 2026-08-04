
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
        }
    }
}
