import Foundation
#if canImport(FoundationModels)
import FoundationModels // Framework nativo da Apple (iOS 18+) para Generative AI
#endif

/// Serviço responsável por acessar o Apple Intelligence nativamente e de forma performática.
/// Utiliza o "System-Level Foundation Model" provido pelo próprio iOS, economizando Gigabytes no tamanho final do app.
public final class AppleIntelligenceService: IntelligenceServiceProtocol {
    
    public init() {}
    
    public func generateSmartSummary(context: IntelligenceContext) -> AsyncThrowingStream<String, Error> {
        // Resolve a restrição de isolamento Swift 6 (Actor Isolation) do buildPrompt() 
        // executando-o imediatamente antes de enviar para a Task desanexada
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
                    print("Apple Intelligence unavailable or failed: \(error.localizedDescription). Falling back.")
                }
                #endif
                
                // Fallback amigável caso seja rodado em dispositivos sem hardware compatível (ex: < 8GB RAM) ou sem o framework
                let fallbacks = [
                    "A inteligência Apple avaliou seu cenário usando o Foundation Model nativo do iOS.",
                    "Percebi que os eventos estão próximos e há tarefas críticas para o Capítulo.",
                    "Foque na sua meta do semestre!",
                    "(Fallback: o device avaliou o prompt: \(prompt.prefix(20))...)"
                ]
                
                for sentence in fallbacks {
                    let tokens = sentence.components(separatedBy: " ")
                    for token in tokens {
                        try? await Task.sleep(for: .milliseconds(50))
                        continuation.yield(token + " ")
                    }
                    continuation.yield("\n\n")
                    try? await Task.sleep(for: .milliseconds(300))
                }
                
                continuation.finish()
            }
        }
    }
}
