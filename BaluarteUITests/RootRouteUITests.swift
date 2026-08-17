import XCTest

/// A máquina de estados que decide a tela inteira. Cada rota existe porque alguém
/// ficaria preso sem ela — a de recusa foi acrescentada justamente porque quem era
/// recusado voltava à busca sem explicação.
final class RootRouteUITests: BaluarteUITestCase {

    func testSignedOutLandsOnLogin() {
        let app = launch(route: .unauthenticated)
        assertExists(app.otherElements["root.login"], "Sem sessão, a rota tem de ser o login.")
    }

    func testFirstOpenShowsOnboardingBeforeLogin() {
        let app = launch(route: .unauthenticated, freshOnboarding: true)

        // O onboarding vem antes do login e some para sempre depois de visto.
        assertAbsent(
            app.otherElements["root.login"],
            "O login não pode aparecer antes do onboarding no primeiro lançamento.",
            settleAnchor: app.buttons.firstMatch
        )
    }

    func testWithoutMembershipLandsOnChapterSelection() {
        let app = launch(route: .chapterSelection)
        assertExists(
            app.otherElements["root.chapterSelection"],
            "Quem tem conta e nenhum vínculo escolhe um Capítulo."
        )
    }

    /// Sem esta rota, quem pediu entrada ficava parado na tela de busca sem saber que
    /// já tinha pedido.
    func testPendingRequestLandsOnApproval() {
        let app = launch(route: .pendingApproval)
        assertExists(
            app.otherElements["root.pendingApproval"],
            "Com solicitação pendente, a rota é a fila de aprovação."
        )
    }

    func testRejectedRequestLandsOnItsOwnScreen() {
        let app = launch(route: .rejected)
        assertExists(
            app.otherElements["root.rejected"],
            "Uma recusa tem tela própria: sem ela a pessoa volta à busca sem motivo."
        )
    }

    func testWithMembershipLandsOnTheApp() {
        let app = launch(route: .app)
        assertExists(app.otherElements["root.app"], "Com vínculo ativo, a rota é o app.")
        assertExists(app.buttons["home.chapter"], "A tela inicial tem a porta do Capítulo.")
        assertExists(app.buttons["home.profile"], "E a do perfil.")
    }
}
