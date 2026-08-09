import Foundation

public protocol PushServiceProtocol {
    /// Idempotente: o mesmo aparelho reenvia o token a cada lançamento, e o servidor
    /// trata isso como atualização, não como duplicata.
    func register(token: String) async
    func unregister(token: String) async
}
