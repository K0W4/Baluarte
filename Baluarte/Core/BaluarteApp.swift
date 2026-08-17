
import SwiftUI

@main
struct BaluarteApp: App {
    @UIApplicationDelegateAdaptor(PushRegistrar.self) private var pushRegistrar

    @State private var authViewModel: AuthViewModel
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true

    init() {
        NotificationService.shared.configure()

        #if DEBUG
        // Os testes de interface abrem o app com serviços determinísticos em vez da
        // rede. O seam já existia: o `AuthViewModel` recebe tudo por init.
        if let configuration = UITestConfiguration.fromLaunchArguments {
            UITestLaunch.resetPersistedFlags()
            _authViewModel = State(initialValue: configuration.makeAuthViewModel())
            return
        }
        #endif

        _authViewModel = State(initialValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
                .task {
                    #if DEBUG
                    // O deslogar do primeiro lançamento jogaria toda rota de teste em
                    // `.unauthenticated`, e pedir push abre um alerta do sistema por
                    // cima da tela que o teste está tentando ler.
                    if UITestConfiguration.fromLaunchArguments != nil { return }
                    #endif

                    await PushRegistrar.shared.registerIfAuthorized()
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
