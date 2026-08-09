import Foundation

/// A auditoria só é lida por função: `access_change_log` não tem policy alguma para
/// `authenticated`, exatamente como `invite_attempt` e `notification_outbox`. Não há
/// escrita aqui de propósito -- quem escreve são os gatilhos, e um log que o app pode
/// alimentar é um log que o app pode falsificar.
public protocol AuditServiceProtocol {
    /// Restrita ao Fundador do Capítulo, no servidor.
    func chapterAccessLog(chapterId: UUID, limit: Int, beforeId: Int?) async throws -> [AccessChangeEntry]

    /// Restrita a quem é administrador de plataforma, no servidor.
    func platformAccessLog(limit: Int, beforeId: Int?) async throws -> [AccessChangeEntry]
}
