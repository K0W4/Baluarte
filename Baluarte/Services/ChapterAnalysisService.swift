import Foundation
import NaturalLanguage

struct MandatoryDay {
    /// Forma canônica em português. É contra ela que o título do evento é comparado,
    /// então traduzir este valor quebraria o casamento semântico.
    let name: String
    let month: Int

    var displayName: String {
        switch name {
        case "Dia Devocional": return String(localized: "Dia Devocional")
        case "Dia em Memória a Jacques DeMolay": return String(localized: "Dia em Memória a Jacques DeMolay")
        case "Dia das Mães": return String(localized: "Dia das Mães")
        case "Dia dos Pais": return String(localized: "Dia dos Pais")
        case "Dia do Patriota": return String(localized: "Dia do Patriota")
        case "Dia Educacional": return String(localized: "Dia Educacional")
        case "Dia do Meu Governo": return String(localized: "Dia do Meu Governo")
        case "Dia em Memória a Frank S. Land": return String(localized: "Dia em Memória a Frank S. Land")
        case "Dia do Conforto": return String(localized: "Dia do Conforto")
        default: return name
        }
    }
}

final class ChapterAnalysisService: ChapterAnalysisServiceProtocol {
    
    private let mandatoryCommittees = [
        "Hospitalaria",
        "Entretenimento",
        "Auditoria",
        "Finanças",
        "Sindicância" // (Incremento de Novos)
    ]
    
    private let mandatoryDays = [
        MandatoryDay(name: "Dia Devocional", month: 3),
        MandatoryDay(name: "Dia em Memória a Jacques DeMolay", month: 3),
        MandatoryDay(name: "Dia das Mães", month: 5),
        MandatoryDay(name: "Dia dos Pais", month: 8),
        MandatoryDay(name: "Dia do Patriota", month: 9),
        MandatoryDay(name: "Dia Educacional", month: 10),
        MandatoryDay(name: "Dia do Meu Governo", month: 11),
        MandatoryDay(name: "Dia em Memória a Frank S. Land", month: 11),
        MandatoryDay(name: "Dia do Conforto", month: 12)
    ]
    
    func generateAnalysis(members: [Member], events: [Event], committees: [Committee]) async throws -> [RawAnalysis] {
        var analyses: [RawAnalysis] = []
        let now = Date()
        let calendar = Calendar.current
        
        analyses.append(contentsOf: analyzeMembership(members: members, calendar: calendar, now: now))
        
        analyses.append(contentsOf: analyzeCommittees(committees: committees))
        
        analyses.append(contentsOf: analyzeEventsWithNLP(events: events, calendar: calendar, now: now))
        
        analyses.append(contentsOf: analyzeEngagement(members: members, events: events, now: now))
        
        analyses.append(contentsOf: analyzeFinancial(calendar: calendar, now: now))
        
        return analyses
    }
    
    // MARK: - Análises Específicas
    
    private func analyzeMembership(members: [Member], calendar: Calendar, now: Date) -> [RawAnalysis] {
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        let endOfSemesterMonth = month <= 6 ? 6 : 12
        let endOfSemesterDate = calendar.date(from: DateComponents(year: year, month: endOfSemesterMonth, day: 30)) ?? now
        
        var agingOutCount = 0
        for member in members where member.isActive && !member.isSenior {
            if let birthdate = member.birthdate {
                let ageComponents = calendar.dateComponents([.year], from: birthdate, to: endOfSemesterDate)
                if let years = ageComponents.year, years >= 21 {
                    agingOutCount += 1
                }
            }
        }
        
        if agingOutCount > 0 {
            return [RawAnalysis(
                category: .membership,
                severity: agingOutCount >= 3 ? .actionRequired : .warning,
                contextData: ["agingOutCount": "\(agingOutCount)"],
                fallbackTitle: "Renovação Necessária",
                fallbackMessage: "\(agingOutCount) membro(s) completarão 21 anos neste semestre. Meta de iniciação: pelo menos \(agingOutCount) novos irmãos."
            )]
        }
        return []
    }
    
    private func analyzeCommittees(committees: [Committee]) -> [RawAnalysis] {
        var results: [RawAnalysis] = []
        let currentCommitteeNames = committees.map { $0.name.lowercased() }
        
        for mandatory in mandatoryCommittees {
            let exists = currentCommitteeNames.contains { $0.contains(mandatory.lowercased()) }
            if !exists {
                results.append(RawAnalysis(
                    category: .structure,
                    severity: .actionRequired,
                    contextData: ["missingCommittee": mandatory],
                    fallbackTitle: "Comissão Ausente",
                    fallbackMessage: "A comissão de \(mandatory) é estatutariamente obrigatória e não está ativa."
                ))
            }
        }
        return results
    }
    
    private func analyzeEventsWithNLP(events: [Event], calendar: Calendar, now: Date) -> [RawAnalysis] {
        var results: [RawAnalysis] = []
        let currentMonth = calendar.component(.month, from: now)
        let isFirstSemester = currentMonth <= 6
        
        let semesterMandatoryDays = mandatoryDays.filter { day in
            let dayIsFirstSemester = day.month <= 6
            return dayIsFirstSemester == isFirstSemester
        }
        
        for mandatoryDay in semesterMandatoryDays {
            var isDayCovered = false
            
            for event in events {
                let eventText = "\(event.title) \(event.notes ?? "")"
                if matchesSemantically(text: eventText, target: mandatoryDay.name) {
                    isDayCovered = true
                    break
                }
            }
            
            if !isDayCovered {
                results.append(RawAnalysis(
                    category: .calendar,
                    severity: .warning,
                    contextData: ["upcomingEvent": mandatoryDay.name],
                    fallbackTitle: String(localized: "Dia Obrigatório Pendente"),
                    fallbackMessage: String(format: String(localized: "O Capítulo ainda não tem um evento ou atividade planejada para o '%@' neste semestre."), mandatoryDay.displayName)
                ))
            }
        }
        
        return results
    }
    
    // MARK: - NLP Engine (Apple Foundation Models)
    
    private func matchesSemantically(text: String, target: String) -> Bool {
        let basicMatch = text.lowercased().contains(target.lowercased())
        if basicMatch { return true }
        
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .portuguese) else {
            return false // Se o modelo não estiver no on-device, cai no false (já que o basicMatch falhou)
        }
        
        let distance = embedding.distance(between: text.lowercased(), and: target.lowercased())
        
        return distance < 0.65
    }
    
    // MARK: - Frequência e Engajamento
    
    private func analyzeEngagement(members: [Member], events: [Event], now: Date) -> [RawAnalysis] {
        let pastEvents = events.filter { $0.scheduledDate < now }
                               .sorted { $0.scheduledDate > $1.scheduledDate }
        
        guard pastEvents.count >= 3 else { return [] }
        let lastThreeEvents = Array(pastEvents.prefix(3))
        
        var membersWithConsecutiveAbsences: [Member] = []
        
        for member in members where member.isActive {
            let missedAllThree = lastThreeEvents.allSatisfy { event in
                let attendees = event.confirmedAttendees ?? []
                return !attendees.contains(member.id)
            }
            
            if missedAllThree {
                membersWithConsecutiveAbsences.append(member)
            }
        }
        
        if !membersWithConsecutiveAbsences.isEmpty {
            let names = membersWithConsecutiveAbsences.map { $0.fullName }.joined(separator: ", ")
            return [RawAnalysis(
                category: .engagement,
                severity: .warning,
                contextData: ["absentMembers": names, "count": "\(membersWithConsecutiveAbsences.count)"],
                fallbackTitle: "Queda de Engajamento",
                fallbackMessage: "\(membersWithConsecutiveAbsences.count) irmão(s) faltaram às últimas 3 reuniões. A Comissão de Hospitalaria deve entrar em contato para verificar se está tudo bem."
            )]
        }
        
        return []
    }
    
    // MARK: - Planejamento Financeiro
    
    private func analyzeFinancial(calendar: Calendar, now: Date) -> [RawAnalysis] {
        var results: [RawAnalysis] = []
        let currentMonth = calendar.component(.month, from: now)
        
        if currentMonth == 2 || currentMonth == 3 {
            results.append(RawAnalysis(
                category: .financial,
                severity: currentMonth == 3 ? .actionRequired : .info,
                contextData: ["deadline": "Renovação Anual (Capitação)"],
                fallbackTitle: "Prazo Administrativo",
                fallbackMessage: "Lembrete: O prazo para o pagamento da Capitação Anual e envio do relatório ao Supremo Conselho está próximo. O caixa está preparado?"
            ))
        }
        
        if currentMonth == 6 || currentMonth == 12 {
            results.append(RawAnalysis(
                category: .financial,
                severity: .warning,
                contextData: ["deadline": "Fechamento de Caixa"],
                fallbackTitle: "Fim do Semestre",
                fallbackMessage: "O semestre está acabando. É hora de organizar as contas, fechar o caixa e preparar o balanço financeiro para a próxima gestão e para a Auditoria."
            ))
        }
        
        return results
    }
}
