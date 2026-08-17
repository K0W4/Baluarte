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

    /// Os dublês nascem no corpo, não no valor padrão do parâmetro: o alvo declara
    /// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, e uma expressão padrão é avaliada em
    /// contexto nonisolated — chamar ali um inicializador isolado ao MainActor rende um
    /// aviso por parâmetro.
    private func makeViewModel(
        auth: TestMockAuthService? = nil,
        store: TestMockSessionStore? = nil,
        membership: TestMockMembershipService? = nil,
        joinRequest: TestMockJoinRequestService? = nil,
        profile: TestMockProfileService? = nil,
        chapter: TestMockChapterService? = nil
    ) -> AuthViewModel {
        AuthViewModel(
            authService: auth ?? TestMockAuthService(),
            profileService: profile ?? TestMockProfileService(),
            membershipService: membership ?? TestMockMembershipService(),
            joinRequestService: joinRequest ?? TestMockJoinRequestService(),
            chapterService: chapter ?? TestMockChapterService(),
            sessionStore: store ?? TestMockSessionStore()
        )
    }

    private func makeChapter(name: String) -> Chapter {
        Chapter(id: UUID(), name: name, number: 1, uf: "RS", city: "Porto Alegre")
    }

    private func makeMembership(chapterId: UUID, memberId: UUID) -> ChapterMembership {
        ChapterMembership(
            id: UUID(), chapterId: chapterId, memberId: memberId,
            fullName: "Membro de Teste", status: .active, createdAt: Date()
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

    // MARK: - O que o widget enxerga

    /// Antes disto o app group carregava só o vínculo aberto, então o widget não tinha
    /// como oferecer o segundo Capítulo a quem tem dupla filiação — nem como nomear o
    /// primeiro.
    @Test("os dois Capítulos chegam ao app group, com nome")
    func testSharedChaptersCarryBothChapters() async throws {
        let userId = UUID()
        let first = makeChapter(name: "Capítulo Alfa")
        let second = makeChapter(name: "Capítulo Beta")

        let chapter = TestMockChapterService()
        chapter.chaptersById = [first.id: first, second.id: second]

        let membership = TestMockMembershipService()
        membership.membershipsToReturn = [
            makeMembership(chapterId: first.id, memberId: userId),
            makeMembership(chapterId: second.id, memberId: userId)
        ]

        let profile = TestMockProfileService()
        profile.profileToReturn = UserProfile(id: userId, fullName: "Membro de Teste", activeChapterId: first.id, createdAt: Date())

        let auth = TestMockAuthService()
        auth.sessionToReturn = try TestSession.make(userId: userId)

        let store = TestMockSessionStore()
        let viewModel = makeViewModel(auth: auth, store: store, membership: membership,
                                      profile: profile, chapter: chapter)

        await waitUntil { viewModel.route == .app }

        #expect(viewModel.sharedChapters.map(\.name) == ["Capítulo Alfa", "Capítulo Beta"])
        #expect(viewModel.chaptersById.count == 2)
        #expect(store.saves.last?.chapters.map(\.name) == ["Capítulo Alfa", "Capítulo Beta"])
    }

    /// O id que atravessa é o do vínculo, não o do Capítulo: é o vínculo que filtra
    /// tarefas e marca presença, e trocar um pelo outro mostraria o Capítulo certo com
    /// as tarefas de ninguém.
    @Test("o que atravessa é o id do vínculo")
    func testSharedChaptersCarryTheMembershipId() async throws {
        let userId = UUID()
        let chapterRow = makeChapter(name: "Capítulo Alfa")
        let bond = makeMembership(chapterId: chapterRow.id, memberId: userId)

        let chapter = TestMockChapterService()
        chapter.chaptersById = [chapterRow.id: chapterRow]

        let membership = TestMockMembershipService()
        membership.membershipsToReturn = [bond]

        let profile = TestMockProfileService()
        profile.profileToReturn = UserProfile(id: userId, fullName: "Membro de Teste", activeChapterId: chapterRow.id, createdAt: Date())

        let auth = TestMockAuthService()
        auth.sessionToReturn = try TestSession.make(userId: userId)

        let viewModel = makeViewModel(auth: auth, membership: membership, profile: profile, chapter: chapter)
        await waitUntil { viewModel.route == .app }

        #expect(viewModel.sharedChapters.map(\.membershipId) == [bond.id])
        #expect(viewModel.sharedChapters.map(\.chapterId) == [chapterRow.id])
        #expect(viewModel.chapterName(for: bond) == "Capítulo Alfa")
    }

    /// Um vínculo cujo Capítulo não pôde ser resolvido fica de fora: uma linha em
    /// branco no seletor é pior do que uma opção a menos.
    @Test("Capítulo sem nome não vira opção sem nome")
    func testUnresolvedChapterIsLeftOut() async throws {
        let userId = UUID()
        let known = makeChapter(name: "Capítulo Alfa")
        let unknownChapterId = UUID()

        let chapter = TestMockChapterService()
        chapter.chaptersById = [known.id: known]

        let membership = TestMockMembershipService()
        membership.membershipsToReturn = [
            makeMembership(chapterId: known.id, memberId: userId),
            makeMembership(chapterId: unknownChapterId, memberId: userId)
        ]

        let profile = TestMockProfileService()
        profile.profileToReturn = UserProfile(id: userId, fullName: "Membro de Teste", activeChapterId: known.id, createdAt: Date())

        let auth = TestMockAuthService()
        auth.sessionToReturn = try TestSession.make(userId: userId)

        let viewModel = makeViewModel(auth: auth, membership: membership, profile: profile, chapter: chapter)
        await waitUntil { viewModel.route == .app }

        #expect(viewModel.memberships.count == 2)
        #expect(viewModel.sharedChapters.map(\.name) == ["Capítulo Alfa"])
    }

    @Test("sair da conta apaga a lista de Capítulos do widget")
    func testSignOutClearsChapters() async throws {
        let userId = UUID()
        let chapterRow = makeChapter(name: "Capítulo Alfa")

        let chapter = TestMockChapterService()
        chapter.chaptersById = [chapterRow.id: chapterRow]

        let membership = TestMockMembershipService()
        membership.membershipsToReturn = [makeMembership(chapterId: chapterRow.id, memberId: userId)]

        let profile = TestMockProfileService()
        profile.profileToReturn = UserProfile(id: userId, fullName: "Membro de Teste", activeChapterId: chapterRow.id, createdAt: Date())

        let auth = TestMockAuthService()
        auth.sessionToReturn = try TestSession.make(userId: userId)

        let viewModel = makeViewModel(auth: auth, membership: membership, profile: profile, chapter: chapter)
        await waitUntil { viewModel.route == .app }

        await viewModel.signOut()

        #expect(viewModel.chaptersById.isEmpty)
        #expect(viewModel.sharedChapters.isEmpty)
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
