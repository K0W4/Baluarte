import Foundation

public protocol IntelligenceServiceProtocol: Sendable {
    func generateSmartSummary(context: IntelligenceContext) -> AsyncThrowingStream<String, Error>
}
