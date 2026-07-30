import SwiftUI
import Observation

@Observable
final class AnalysisViewModel {
    var displayedAnalyses: [DisplayedAnalysis] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    private let analyticsService: ChapterAnalysisServiceProtocol
    private let translationService: AnalysisTranslationServiceProtocol
    private let memberService: MemberServiceProtocol
    private let eventService: EventServiceProtocol
    private let committeeService: CommitteeServiceProtocol
    
    init(
        analyticsService: ChapterAnalysisServiceProtocol = ChapterAnalysisService(),
        translationService: AnalysisTranslationServiceProtocol = AnalysisTranslationService(),
        memberService: MemberServiceProtocol = Services.member,
        eventService: EventServiceProtocol = Services.event,
        committeeService: CommitteeServiceProtocol = Services.committee
    ) {
        self.analyticsService = analyticsService
        self.translationService = translationService
        self.memberService = memberService
        self.eventService = eventService
        self.committeeService = committeeService
    }
    
    var groupedAnalyses: [(key: AnalysisCategory, value: [DisplayedAnalysis])] {
        let grouped = Dictionary(grouping: displayedAnalyses, by: { $0.category })
        let order: [AnalysisCategory] = [.membership, .structure, .calendar, .engagement, .financial]
        return order.compactMap { category in
            if let analyses = grouped[category], !analyses.isEmpty {
                return (key: category, value: analyses)
            }
            return nil
        }
    }

    var consolidatedGroupedAnalyses: [(key: AnalysisCategory, value: [ConsolidatedInsight])] {
        let order: [AnalysisCategory] = [.membership, .structure, .calendar, .engagement, .financial]

        return order.compactMap { category in
            let categoryAnalyses = displayedAnalyses.filter { $0.category == category }
            guard !categoryAnalyses.isEmpty else { return nil }

            let maxSeverity = categoryAnalyses.map(\.severity).max(by: { severityRank($0) < severityRank($1) }) ?? .info

            let consolidated = ConsolidatedInsight(
                category: category,
                severity: maxSeverity,
                items: categoryAnalyses,
                primaryActionLabel: categoryAnalyses.compactMap(\.suggestedActionLabel).first
            )

            return (key: category, value: [consolidated])
        }
    }

    private func severityRank(_ severity: AnalysisSeverity) -> Int {
        switch severity {
        case .info: return 0
        case .warning: return 1
        case .actionRequired: return 2
        }
    }
    
    @MainActor
    func fetchAnalyses(chapterId: UUID) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            async let fetchMembers = memberService.fetchMembers(for: chapterId)
            async let fetchEvents = eventService.fetchEvents(for: chapterId)
            async let fetchCommittees = committeeService.fetchCommittees(for: chapterId)
            
            let (members, events, committees) = try await (fetchMembers, fetchEvents, fetchCommittees)
            
            let rawAnalyses = try await analyticsService.generateAnalysis(
                members: members,
                events: events,
                committees: committees
            )
            
            var newDisplayed: [DisplayedAnalysis] = []
            
            for raw in rawAnalyses {
                let translated = try await translationService.translate(analysis: raw)
                newDisplayed.append(translated)
            }
            
            self.displayedAnalyses = newDisplayed
        } catch {
            self.errorMessage = "Falha ao gerar análise da gestão. Tente novamente mais tarde."
            print("Erro ao gerar análise: \(error)")
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isLoading = false
        }
    }
}
