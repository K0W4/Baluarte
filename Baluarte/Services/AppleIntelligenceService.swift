import Foundation
#if canImport(FoundationModels)
import FoundationModels // Framework nativo da Apple (iOS 18+) para Generative AI
#endif

public final class AppleIntelligenceService: IntelligenceServiceProtocol {
    
    public init() {}
    
    public func generateSmartSummary(context: IntelligenceContext) -> AsyncThrowingStream<String, Error> {
        let prompt = context.buildPrompt()
        
        return AsyncThrowingStream { continuation in
            Task.detached(priority: .userInitiated) {
                #if canImport(FoundationModels)
                do {
                    let session = LanguageModelSession(
                        instructions: "Você é um conselheiro conciso de um Capítulo DeMolay. Responda SEMPRE em no máximo 3 frases curtas e motivadoras. Nunca repita frases. Seja direto."
                    )
                    
                    let stream = session.streamResponse(to: prompt)
                    var previousContent = ""
                    for try await fragment in stream {
                        let currentContent = fragment.content
                        if currentContent.count > previousContent.count {
                            let delta = String(currentContent.dropFirst(previousContent.count))
                            continuation.yield(delta)
                        }
                        previousContent = currentContent
                    }
                    
                    continuation.finish()
                    return
                } catch {
                    continuation.finish(throwing: IntelligenceUnavailableError())
                }
                #else
                // Não existe caminho de reserva, e é de propósito. O que existia aqui
                // transmitia quatro frases fixas token a token, com a mesma animação de
                // digitação de uma geração real — uma delas afirmando que "a inteligência
                // Apple avaliou seu cenário", sobre um modelo que não rodou, e outra
                // vazando um trecho do prompt na tela. Um Capítulo tomava decisão de gestão
                // em cima de texto inventado. Sem modelo, a tela diz que não há resumo.
                _ = prompt
                continuation.finish(throwing: IntelligenceUnavailableError())
                #endif
            }
        }
    }
}

/// O aparelho não tem Apple Intelligence disponível, ou o modelo recusou. É diferente de
/// falha de rede: nenhuma quantidade de tentar de novo resolve.
public struct IntelligenceUnavailableError: Error, LocalizedError {
    public init() {}

    public var errorDescription: String? {
        String(localized: "O resumo inteligente precisa da Apple Intelligence, que não está disponível neste iPhone.")
    }
}
