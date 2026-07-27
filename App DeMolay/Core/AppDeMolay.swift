
import SwiftUI

@main
struct AppDeMolay: App {
    @State private var authViewModel = AuthViewModel()
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
                .task {
                    if isFirstLaunch {
                        // Força logout em caso de reinstalação limpa, pois o Keychain persiste.
                        await authViewModel.signOut()
                        isFirstLaunch = false
                    }
                }
        }
    }
}
