import Foundation
import NaturalLanguage

final class AnalysisTranslationService: AnalysisTranslationServiceProtocol {
    
    
    func translate(analysis: RawAnalysis) async throws -> DisplayedAnalysis {
        let generatedTitle: String
        var generatedMessage: String
        var suggestedAction: String?
        
        switch analysis.category {
        case .membership:
            if let countStr = analysis.contextData["agingOutCount"], let count = Int(countStr) {
                generatedTitle = "Oportunidade de Renovação"
                generatedMessage = "\(count) irmão(s) completam 21 anos neste semestre. Hora de planejar a próxima iniciação."
                suggestedAction = "Ver Membros"
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .structure:
            if let missing = analysis.contextData["missingCommittee"] {
                generatedTitle = missing
                generatedMessage = ""
                suggestedAction = "Criar Comissão"
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .calendar:
            if let event = analysis.contextData["upcomingEvent"] {
                let isCerimonial = isRelatedToCeremony(event)
                
                if isCerimonial {
                    generatedTitle = event
                    generatedMessage = ""
                } else {
                    generatedTitle = event
                    generatedMessage = ""
                }
                
                suggestedAction = "Criar Evento"
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .engagement:
            if let countStr = analysis.contextData["count"], let count = Int(countStr) {
                generatedTitle = "Acolhimento Fraternal"
                generatedMessage = "\(count) irmão(s) faltaram às últimas 3 reuniões. A Hospitalaria deve entrar em contato."
                suggestedAction = nil
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .financial:
            if let deadline = analysis.contextData["deadline"] {
                if deadline.contains("Capitação") {
                    generatedTitle = "Saúde Financeira em Dia"
                    generatedMessage = "Prazo da Capitação Anual se aproxima. Verifique se o caixa está preparado."
                } else {
                    generatedTitle = "Fechamento de Ouro"
                    generatedMessage = "Fim de semestre: organize as contas e feche o caixa para a próxima gestão."
                }
                suggestedAction = nil
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        }
        
        return DisplayedAnalysis(
            rawAnalysis: analysis,
            generatedTitle: generatedTitle,
            generatedMessage: generatedMessage,
            actionLabel: suggestedAction
        )
    }
    
    
    private func isRelatedToCeremony(_ text: String) -> Bool {
        guard let embedding = NLEmbedding.wordEmbedding(for: .portuguese) else { return false }
        
        let targetWords = ["Iniciação", "Elevação", "Instalação", "Cerimônia", "Ritualística"]
        
        for word in text.components(separatedBy: .whitespaces) {
            for target in targetWords {
                let distance = embedding.distance(between: word.lowercased(), and: target.lowercased())
                if distance < 0.8 { // Limiar de similaridade semântica
                    return true
                }
            }
        }
        return false
    }
}
