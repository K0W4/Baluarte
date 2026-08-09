import XCTest

/// O que some sem permissão.
///
/// `.requires(_:)` é enfeite de interface e o projeto trata isso como enfeite de
/// propósito: a recusa de verdade é da RLS, e `supabase/tests/rls.sh` é quem prova.
/// O que estes testes garantem é o outro lado — que a tela não oferece um botão que o
/// servidor vai recusar, o que faria a pessoa achar que o app está quebrado.
final class PermissionAffordanceUITests: BaluarteUITestCase {

    private func openChapter(access: String) -> XCUIApplication {
        let app = launch(route: .app, access: access)
        let chapterButton = app.buttons["home.chapter"]
        assertExists(chapterButton, "A porta do Capítulo tem de estar na barra.")
        chapterButton.tap()
        return app
    }

    func testOwnerSeesEveryAdministrativeAffordance() {
        let app = openChapter(access: "owner")

        assertExists(app.buttons["chapter.joinRequests"], "Fundador revisa entrada.")
        assertExists(app.buttons["chapter.invites"], "Fundador gera convite.")
        assertExists(app.buttons["chapter.accessLog"], "Fundador lê a auditoria.")
    }

    /// A auditoria conta quem rebaixou quem, então fica com o Fundador. Administrador
    /// comum administra o Capítulo e não vê isso — e a RPC recusa por conta própria.
    func testAdminAdministersButDoesNotSeeTheAccessLog() {
        let app = openChapter(access: "admin")

        assertExists(app.buttons["chapter.joinRequests"], "Administrador revisa entrada.")
        assertExists(app.buttons["chapter.invites"], "Administrador gera convite.")
        assertAbsent(
            app.buttons["chapter.accessLog"],
            "A auditoria é do Fundador; administrador não pode nem ver o caminho.",
            settleAnchor: app.buttons["chapter.invites"]
        )
    }

    func testPlainMemberSeesNoAdministration() {
        let app = openChapter(access: "member")

        let anchor = app.staticTexts["chapter.name"]
        assertAbsent(app.buttons["chapter.joinRequests"], "Membro não revisa entrada.", settleAnchor: anchor)
        assertAbsent(app.buttons["chapter.invites"], "Membro não gera convite.", settleAnchor: anchor)
        assertAbsent(app.buttons["chapter.accessLog"], "Membro não lê a auditoria.", settleAnchor: anchor)
    }

    /// Sair do Capítulo não é administração: é de quem está dentro, em qualquer nível.
    func testLeavingTheChapterIsAvailableToEveryone() {
        let app = openChapter(access: "member")
        assertExists(app.buttons["chapter.leave"], "Qualquer um pode sair do próprio Capítulo.")
    }

    func testPlatformDoorOnlyForPlatformAdmins() {
        let app = launch(route: .app, platformAdmin: true)
        app.buttons["home.profile"].tap()
        assertExists(app.buttons["profile.platform"], "Administrador de plataforma tem a porta no perfil.")
    }

    /// Ser Fundador do próprio Capítulo não dá acesso de plataforma: quem aprova
    /// fundação aprova a de qualquer Capítulo do país, e é por isso que os dois nunca
    /// foram a mesma coisa.
    func testOwnerIsNotAPlatformAdmin() {
        let app = launch(route: .app, access: "owner", platformAdmin: false)
        let profileButton = app.buttons["home.profile"]
        assertExists(profileButton, "A porta do perfil tem de estar na barra.")
        profileButton.tap()

        assertAbsent(
            app.buttons["profile.platform"],
            "Fundador de Capítulo não administra a plataforma.",
            settleAnchor: app.buttons["profile.signOut"]
        )
    }
}
