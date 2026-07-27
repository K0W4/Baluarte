import Foundation

protocol ChapterAnalysisServiceProtocol {
    func generateAnalysis(members: [Member], events: [Event], committees: [Committee]) async throws -> [RawAnalysis]
}

protocol AnalysisTranslationServiceProtocol {
    func translate(analysis: RawAnalysis) async throws -> DisplayedAnalysis
}
