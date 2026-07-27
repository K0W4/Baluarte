import Foundation

final class AnalysisTranslationService: AnalysisTranslationServiceProtocol {
    
    // Na fase atual de desenvolvimento (Pré-iOS 18 SDK completo ou sem API do Supabase),
    // usaremos um mock determinístico que simula a IA gerando o texto humanizado.
    // Futuramente, esta classe fará a requisição para a Edge Function ou usará o framework `LanguageModel` (Apple Intelligence).
    
    func translate(analysis: RawAnalysis) async throws -> DisplayedAnalysis {
        // Simula o tempo de latência de uma chamada de rede ou processamento de LLM local
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
        
        let generatedTitle: String
        let generatedMessage: String
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
                generatedTitle = "Planeje o Sucesso"
                generatedMessage = "O **\(event)** já está no horizonte! Planejar essa data com antecedência garante uma atividade memorável e muito mais presença das nossas famílias."
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
}
