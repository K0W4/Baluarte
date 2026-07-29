import Foundation

/// Protocolo que define a comunicação com Foundation Models (LLMs on-device).
public protocol IntelligenceServiceProtocol: Sendable {
    /// Gera um resumo inteligente a partir do contexto do Capítulo.
    /// - Parameter context: Os dados brutos do capítulo encapsulados no IntelligenceContext.
    /// - Returns: Uma stream assíncrona gerada pelo modelo para permitir o efeito de digitação (streaming token a token).
    func generateSmartSummary(context: IntelligenceContext) -> AsyncThrowingStream<String, Error>
}
