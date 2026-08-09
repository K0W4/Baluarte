import Foundation

/// O app group e o Keychain são a única visão que o widget e os AppIntents têm da
/// sessão. Escrever isso de um lugar só é o que impede os dois divergirem — e ter um
/// protocolo aqui é o que permite instanciar o `AuthViewModel` num teste sem tocar
/// UserDefaults reais nem recarregar timeline de widget.
public protocol SessionStoreProtocol {
    func save(userId: UUID?, chapterId: UUID?, membershipId: UUID?, accessToken: String, refreshToken: String)
    func clear()
}
