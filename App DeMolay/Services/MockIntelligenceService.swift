import Foundation

/// Mock Service que simula a geração de um texto por um Foundation Model token a token.
/// Utilizado para desenvolvimento e testes unitários.
public final class MockIntelligenceService: IntelligenceServiceProtocol {
    public init() {}
    
    public func generateSmartSummary(context: IntelligenceContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let mockResponse = "Vejo que vocês estão indo muito bem! Não se esqueçam que a Reunião Ritualística está próxima e vocês ainda têm tarefas importantes pendentes. Se focarem agora, alcançarão a meta do semestre com sucesso!"
                let tokens = mockResponse.components(separatedBy: " ")
                
                for token in tokens {
                    // Simula atraso da NPU (100ms) para cada token
                    try? await Task.sleep(nanoseconds: 100_000_000) 
                    continuation.yield(token + " ")
                }
                
                continuation.finish()
            }
        }
    }
}
