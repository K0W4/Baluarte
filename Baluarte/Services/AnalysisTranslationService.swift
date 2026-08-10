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
                generatedTitle = String(localized: "Oportunidade de Renovação")
                generatedMessage = String(
                    format: String(localized: "%lld irmãos completam 21 anos neste semestre. Hora de planejar a próxima iniciação."),
                    count
                )
                suggestedAction = String(localized: "Ver Membros")
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .structure:
            if let missing = analysis.contextData["missingCommittee"] {
                generatedTitle = missing
                generatedMessage = ""
                suggestedAction = String(localized: "Criar Comissão")
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
                
                suggestedAction = String(localized: "Criar Evento")
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .engagement:
            if let countStr = analysis.contextData["count"], let count = Int(countStr) {
                generatedTitle = String(localized: "Acolhimento Fraternal")
                generatedMessage = String(
                    format: String(localized: "%lld irmãos faltaram às últimas 3 reuniões. A Hospitalaria deve entrar em contato."),
                    count
                )
                suggestedAction = nil
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .financial:
            if let deadline = analysis.contextData["deadline"] {
                if deadline.contains("Capitação") {
                    generatedTitle = String(localized: "Saúde Financeira em Dia")
                    generatedMessage = String(localized: "Prazo da Capitação Anual se aproxima. Verifique se o caixa está preparado.")
                } else {
                    generatedTitle = String(localized: "Fechamento de Ouro")
                    generatedMessage = String(localized: "Fim de semestre: organize as contas e feche o caixa para a próxima gestão.")
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
