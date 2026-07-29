import Foundation

enum AnalysisCategory: String, Codable {
    case membership = "membership"
    case structure = "structure"
    case calendar = "calendar"
    case engagement = "engagement"
    case financial = "financial"
}

enum AnalysisSeverity: String, Codable {
    case info = "info"
    case warning = "warning"
    case actionRequired = "actionRequired"
}

struct RawAnalysis: Identifiable, Hashable {
    let id: UUID
    let category: AnalysisCategory
    let severity: AnalysisSeverity
    
    let contextData: [String: String]
    
    let fallbackTitle: String
    let fallbackMessage: String
    
    init(id: UUID = UUID(), category: AnalysisCategory, severity: AnalysisSeverity, contextData: [String: String], fallbackTitle: String, fallbackMessage: String) {
        self.id = id
        self.category = category
        self.severity = severity
        self.contextData = contextData
        self.fallbackTitle = fallbackTitle
        self.fallbackMessage = fallbackMessage
    }
}

struct DisplayedAnalysis: Identifiable, Hashable {
    let id: UUID
    let rawAnalysisId: UUID
    
    let category: AnalysisCategory
    let severity: AnalysisSeverity
    
    let aiGeneratedTitle: String
    let aiGeneratedMessage: String
    let suggestedActionLabel: String? // Ex: "Criar Comissão", "Ver Calendário"
    
    var title: String { aiGeneratedTitle }
    var message: String { aiGeneratedMessage }
    
    init(rawAnalysis: RawAnalysis, generatedTitle: String, generatedMessage: String, actionLabel: String? = nil) {
        self.id = UUID()
        self.rawAnalysisId = rawAnalysis.id
        self.category = rawAnalysis.category
        self.severity = rawAnalysis.severity
        self.aiGeneratedTitle = generatedTitle
        self.aiGeneratedMessage = generatedMessage
        self.suggestedActionLabel = actionLabel
    }
}
