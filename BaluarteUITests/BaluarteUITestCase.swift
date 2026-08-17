import XCTest

/// Base dos testes de interface.
///
/// Duas regras que os testes anteriores quebravam e por isso não provavam nada:
///
/// 1. **Nada de `if elemento.existe { ... }`.** Um teste embrulhado numa condição
///    passa verde justamente quando a tela não carregou, que é o caso que ele deveria
///    pegar. Aqui tudo é asserção.
/// 2. **Nada de comparar frase.** O CI roda em inglês de propósito, então procurar
///    "Convites" quebraria por motivo errado. As âncoras são identificadores de
///    acessibilidade, que não mudam de idioma.
///
/// O app abre com serviços determinísticos (`-uitest`), sem rede e sem sessão real:
/// ver `UITestSupport.swift`.
class BaluarteUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    enum Route: String {
        case unauthenticated
        case chapterSelection
        case pendingApproval
        case rejected
        case app
    }

    @discardableResult
    func launch(
        route: Route = .app,
        access: String = "owner",
        chapters: Int = 1,
        platformAdmin: Bool = false,
        freshOnboarding: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-uitest",
            "-uitest-route", route.rawValue,
            "-uitest-access", access,
            "-uitest-chapters", String(chapters)
        ]
        if platformAdmin { app.launchArguments.append("-uitest-platform-admin") }
        if freshOnboarding { app.launchArguments.append("-uitest-fresh-onboarding") }

        app.launch()
        self.app = app
        return app
    }

    /// Espera de verdade, com asserção no fim. Devolver `Bool` para o chamador decidir
    /// é como se volta a escrever `if` sem querer.
    func assertExists(
        _ element: XCUIElement,
        _ message: String,
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message, file: file, line: line)
    }

    /// A ausência é o ponto de várias destas provas — uma affordance que some sem
    /// permissão. Espera o contrário antes de afirmar, porque a tela leva um instante
    /// para montar e "ainda não apareceu" não é "não existe".
    func assertAbsent(
        _ element: XCUIElement,
        _ message: String,
        settleAnchor: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            settleAnchor.waitForExistence(timeout: 30),
            "A tela não chegou a montar, então a ausência não prova nada.",
            file: file, line: line
        )
        XCTAssertFalse(element.exists, message, file: file, line: line)
    }
}
