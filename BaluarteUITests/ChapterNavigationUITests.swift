import XCTest

/// A divisão que o pacote 12 fez: o que é do Capítulo, o que é da pessoa e o que é da
/// plataforma deixaram de ser uma lista só. Estes testes existem para a pilha não
/// voltar a se formar sem ninguém perceber.
final class ChapterNavigationUITests: BaluarteUITestCase {

    func testChapterScreenNamesTheChapter() {
        let app = launch(route: .app)
        app.buttons["home.chapter"].tap()

        // O nome, o número e a jurisdição não apareciam em lugar nenhum do app antes
        // desta tela.
        assertExists(app.staticTexts["chapter.name"], "A tela do Capítulo diz qual Capítulo é.")
    }

    func testProfileDoesNotCarryChapterAdministration() {
        let app = launch(route: .app, access: "owner")
        let profileButton = app.buttons["home.profile"]
        assertExists(profileButton, "A porta do perfil tem de estar na barra.")
        profileButton.tap()

        let anchor = app.buttons["profile.signOut"]
        assertAbsent(app.buttons["chapter.joinRequests"], "A fila de entrada é do Capítulo, não do perfil.", settleAnchor: anchor)
        assertAbsent(app.buttons["chapter.invites"], "Convites são do Capítulo.", settleAnchor: anchor)
        assertAbsent(app.buttons["chapter.accessLog"], "A auditoria é do Capítulo.", settleAnchor: anchor)
        assertAbsent(app.buttons["chapter.leave"], "Sair do Capítulo é do Capítulo.", settleAnchor: anchor)
    }

    func testChapterScreenDoesNotCarryAccountActions() {
        let app = launch(route: .app)
        app.buttons["home.chapter"].tap()

        let anchor = app.staticTexts["chapter.name"]
        assertAbsent(app.buttons["profile.signOut"], "Sair da conta é da pessoa.", settleAnchor: anchor)
        assertAbsent(app.buttons["profile.deleteAccount"], "Excluir conta é da pessoa.", settleAnchor: anchor)
        assertAbsent(app.buttons["profile.platform"], "A plataforma não é do Capítulo.", settleAnchor: anchor)
    }

    func testPlatformScreenHoldsWhatCrossesChapters() {
        let app = launch(route: .app, platformAdmin: true)
        app.buttons["home.profile"].tap()

        let platformDoor = app.buttons["profile.platform"]
        assertExists(platformDoor, "A porta da plataforma tem de existir para quem administra.")
        platformDoor.tap()

        assertExists(app.buttons["platform.bootstrapQueue"], "Fila de fundação.")
        assertExists(app.buttons["platform.chapterRequests"], "Fila de Capítulos solicitados.")
        assertExists(app.buttons["platform.admins"], "Administradores de plataforma.")
        assertExists(app.buttons["platform.accessLog"], "Histórico da plataforma.")
    }

    /// A troca de Capítulo só faz sentido com dupla filiação, e mostrá-la para quem tem
    /// um vínculo só é oferecer escolha entre uma coisa e ela mesma.
    func testChapterSwitcherOnlyWithDoubleAffiliation() {
        let single = launch(route: .app, chapters: 1)
        assertExists(single.buttons["home.chapter"], "A porta do Capítulo tem de estar na barra.")
        single.buttons["home.chapter"].tap()
        assertAbsent(
            single.staticTexts["chapter.switcher"],
            "Com uma filiação só não há o que trocar.",
            settleAnchor: single.staticTexts["chapter.name"]
        )
        single.terminate()

        let double = launch(route: .app, chapters: 2)
        assertExists(double.buttons["home.chapter"], "A porta do Capítulo tem de estar na barra.")
        double.buttons["home.chapter"].tap()
        assertExists(double.staticTexts["chapter.switcher"], "Com dupla filiação, a troca aparece.")
    }
}
