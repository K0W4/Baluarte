import Foundation
import Testing
import Supabase
@testable import Baluarte

/// A peça mais central do app, e até aqui a única sem cobertura: ela decide entre
/// seis estados de rota, resolve qual vínculo está ativo e alimenta a única visão que
/// o widget tem da sessão. Instanciá-la tocava a rede — o `authStateChanges` era lido
/// direto do cliente Supabase — e é isso que estes testes puderam passar a exercitar.
@MainActor
struct AuthViewModelTests {

    private func makeViewModel(
        auth: TestMockAuthService = TestMockAuthService(),
        store: TestMockSessionStore = TestMockSessionStore(),
        membership: TestMockMembershipService = TestMockMembershipService(),
        joinRequest: TestMockJoinRequestService = TestMockJoinRequestService(),
        profile: TestMockProfileService = TestMockProfileService()
    ) -> AuthViewModel {
        AuthViewModel(
            authService: auth,
            profileService: profile,
            membershipService: membership,
            joinRequestService: joinRequest,
            chapterService: TestMockChapterService(),
            sessionStore: store
        )
    }

    // MARK: - Rota

    @Test("sem sessão a rota é unauthenticated")
    func testUnauthenticatedRoute() async {
        let auth = TestMockAuthService()
        auth.shouldThrowError = true
        let viewModel = makeViewModel(auth: auth)

        // O init dispara checkSession numa Task; esperar o estado sair de .loading é
        // o que torna a asserção sobre a rota honesta.
        await waitUntil { viewModel.route != .loading }

        #expect(viewModel.route == .unauthenticated)
    }

    // MARK: - Estado compartilhado

    @Test("signOut limpa o que o widget lê")
    func testSignOutClearsSharedState() async {
        let auth = TestMockAuthService()
        let store = TestMockSessionStore()
        let viewModel = makeViewModel(auth: auth, store: store)

        await waitUntil { viewModel.route != .loading }
        let before = store.clearCount

        await viewModel.signOut()

        #expect(auth.signOutCallCount == 1)
        #expect(store.clearCount > before)
    }

    // MARK: - Recuperação de senha

    @Test("um link de recuperação válido abre a tela de senha nova")
    func testValidRecoveryLinkOpensTheSheet() async {
        let auth = TestMockAuthService()
        let viewModel = makeViewModel(auth: auth)
        await waitUntil { viewModel.route != .loading }

        let url = URL(string: "baluarte://password-recovery#access_token=abc&type=recovery")
        await viewModel.beginPasswordRecovery(from: try! #require(url))

        #expect(viewModel.isSettingNewPassword)
        #expect(auth.recoveryURLs.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("um link expirado explica isso, e não fala de token")
    func testExpiredRecoveryLinkExplainsItself() async {
        let auth = TestMockAuthService()
        let viewModel = makeViewModel(auth: auth)
        await waitUntil { viewModel.route != .loading }

        auth.shouldThrowError = true
        let url = try! #require(URL(string: "baluarte://password-recovery"))
        await viewModel.beginPasswordRecovery(from: url)

        #expect(!viewModel.isSettingNewPassword)
        #expect(viewModel.errorMessage == String(localized: "Este link de recuperação expirou ou já foi usado. Peça um novo."))
    }

    @Test("salvar a senha nova fecha a tela")
    func testSettingNewPasswordClosesTheSheet() async {
        let auth = TestMockAuthService()
        let viewModel = makeViewModel(auth: auth)
        await waitUntil { viewModel.route != .loading }
        viewModel.isSettingNewPassword = true

        let saved = await viewModel.setNewPassword("senha-nova-123")

        #expect(saved)
        #expect(!viewModel.isSettingNewPassword)
        #expect(auth.updatedPasswords == ["senha-nova-123"])
    }

    @Test("senha recusada pelo servidor mantém a tela aberta")
    func testRejectedPasswordKeepsTheSheetOpen() async {
        let auth = TestMockAuthService()
        let viewModel = makeViewModel(auth: auth)
        await waitUntil { viewModel.route != .loading }
        viewModel.isSettingNewPassword = true
        auth.shouldThrowError = true

        let saved = await viewModel.setNewPassword("curta")

        #expect(!saved)
        #expect(viewModel.isSettingNewPassword)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - Permissões derivadas

    @Test("sem vínculo, permissões são as de membro e nada mais")
    func testPermissionsWithoutMembership() async {
        let viewModel = makeViewModel()
        await waitUntil { viewModel.route != .loading }

        #expect(viewModel.accessLevel == .member)
        #expect(!viewModel.permissions.can(.manageRoster))
        #expect(!viewModel.permissions.can(.manageAdmins))
        #expect(!viewModel.permissions.can(.reviewChapterBootstrap))
    }

    // MARK: -

    /// O `init` dispara trabalho assíncrono, então uma asserção imediata testaria o
    /// estado errado. Espera com teto para não pendurar a suíte se algo travar.
    private func waitUntil(_ condition: () -> Bool, timeout: Duration = .seconds(2)) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() && ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
