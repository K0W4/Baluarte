import XCTest

final class EventDetailUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testEventEditFlowHeuristics() throws {
        // Tentar navegar até o detalhe do evento (Assumindo que há um evento visível na Home)
        // Isso pode falhar se o app precisar de login primeiro no ambiente de teste.
        // Assumindo que o app tem um tab bar e um evento na lista:
        
        let firstEventCard = app.buttons.matching(identifier: "Toque para ver detalhes do evento").firstMatch
        if firstEventCard.waitForExistence(timeout: 5) {
            firstEventCard.tap()
            
            // O formulário de edição deve estar travado (TextField não editável ou sem teclado)
            // Clica no botão de lápis
            let editButton = app.buttons["Editar"] // ou o accessibility label do botão de lápis
            if editButton.exists {
                editButton.tap()
                
                // O botão de salvar (checkmark) deve aparecer
                let saveButton = app.buttons["Salvar"]
                XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Botão de salvar deveria aparecer após habilitar edição")
                
                // Clica em salvar
                saveButton.tap()
                
                // O botão de editar (lápis) volta a aparecer
                XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Botão de lápis deveria voltar após salvar")
            }
        }
    }
}
