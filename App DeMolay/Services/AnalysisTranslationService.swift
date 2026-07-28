import Foundation
import NaturalLanguage

final class AnalysisTranslationService: AnalysisTranslationServiceProtocol {
    
    // Utilizando o framework NaturalLanguage da Apple (Foundation Models clássicos)
    // para extrair sentimento, entidades e adaptar a mensagem dinamicamente.
    
    func translate(analysis: RawAnalysis) async throws -> DisplayedAnalysis {
        let generatedTitle: String
        var generatedMessage: String
        var suggestedAction: String?
        
        switch analysis.category {
        case .membership:
            if let countStr = analysis.contextData["agingOutCount"], let count = Int(countStr) {
                generatedTitle = "Oportunidade de Renovação"
                generatedMessage = "O Capítulo conta com **\(count) irmão(s)** alcançando a maioridade neste semestre! É o momento perfeito para organizarmos uma iniciação e garantirmos novos líderes para nossa ordem."
                suggestedAction = "Ver Membros"
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .structure:
            if let missing = analysis.contextData["missingCommittee"] {
                generatedTitle = "Potencialize sua Gestão"
                generatedMessage = "Para envolver mais irmãos e alavancar nossos resultados, que tal estruturar a **Comissão de \(missing)**? Delegar tarefas é o segredo de um Capítulo dinâmico."
                suggestedAction = "Criar Comissão"
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .calendar:
            if let event = analysis.contextData["upcomingEvent"] {
                // Aplicação de ML (NaturalLanguage Foundation Models): 
                // 1. Sentimento
                let sentimentScore = analyzeSentiment(for: event)
                let isPositive = sentimentScore >= 0.0
                // 2. Word Embeddings (Representação Vetorial Densa - Foundation Model)
                let isCerimonial = isRelatedToCeremony(event)
                
                if isCerimonial {
                    generatedTitle = "Foco na Ritualística"
                    generatedMessage = "O **\(event)** é um evento solene. Garantir a excelência na ritualística é o que define nosso Capítulo!"
                } else {
                    generatedTitle = isPositive ? "Grande Evento à Vista" : "Planeje o Sucesso"
                    let prefix = isPositive ? "Temos uma excelente oportunidade chegando:" : "Fique atento ao nosso calendário:"
                    generatedMessage = "\(prefix) O **\(event)** já está no horizonte! Planejar essa data com antecedência garante uma atividade memorável."
                }
                
                suggestedAction = "Criar Evento"
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .engagement:
            if let countStr = analysis.contextData["count"], let count = Int(countStr) {
                generatedTitle = "Acolhimento Fraternal"
                generatedMessage = "Senti a falta de **\(count) irmão(s)** nas últimas três reuniões. Uma mensagem amigável da **Comissão de Hospitalaria** fará toda a diferença para mostrar que nos importamos com eles."
                suggestedAction = nil
            } else {
                generatedTitle = analysis.fallbackTitle
                generatedMessage = analysis.fallbackMessage
            }
        case .financial:
            if let deadline = analysis.contextData["deadline"] {
                if deadline.contains("Capitação") {
                    generatedTitle = "Saúde Financeira em Dia"
                    generatedMessage = "A época da **Capitação Anual** se aproxima. Um bom planejamento agora garante que o Capítulo mantenha suas obrigações sem correria, mantendo o caixa saudável."
                } else {
                    generatedTitle = "Fechamento de Ouro"
                    generatedMessage = "Nosso semestre foi incrível! Aproveite este momento de transição para deixar as contas organizadas e entregar um caixa redondo para a próxima gestão."
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
    
    // Função auxiliar que utiliza os modelos base (Foundation/CoreML integrados) do NaturalLanguage
    private func analyzeSentiment(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let scoreStr = sentiment?.rawValue, let score = Double(scoreStr) {
            return score
        }
        return 0.0
    }
    
    // Função auxiliar que utiliza Word Embeddings (Foundation Model embutido no iOS)
    // para medir a distância vetorial semântica entre duas palavras.
    private func isRelatedToCeremony(_ text: String) -> Bool {
        guard let embedding = NLEmbedding.wordEmbedding(for: .portuguese) else { return false }
        
        let targetWords = ["Iniciação", "Elevação", "Instalação", "Cerimônia", "Ritualística"]
        
        for word in text.components(separatedBy: .whitespaces) {
            for target in targetWords {
                // Mede a distância no espaço vetorial (0 = idêntico, 2 = opostos)
                let distance = embedding.distance(between: word.lowercased(), and: target.lowercased())
                if distance < 0.8 { // Limiar de similaridade semântica
                    return true
                }
            }
        }
        return false
    }
}
