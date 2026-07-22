import Foundation

public struct MockGoalService: GoalServiceProtocol {
    public init() {}
    
    public func fetchGoals(for chapterId: UUID) async throws -> [Goal] {
        return [
            Goal(id: UUID(), chapterId: chapterId, type: "Financeira", title: "Caixa do Semestre", description: "Arrecadar fundos para o conclave", currentValue: 1200.0, targetValue: 3000.0, targetDate: Date().addingTimeInterval(86400 * 30), createdAt: Date()),
            Goal(id: UUID(), chapterId: chapterId, type: "Membresia", title: "Novos Iniciáticos", description: "Bater a meta da gestão", currentValue: 3.0, targetValue: 5.0, targetDate: Date().addingTimeInterval(86400 * 60), createdAt: Date()),
            Goal(id: UUID(), chapterId: chapterId, type: "Engajamento", title: "Presença nas reuniões", description: "Aumentar a participação ativa", currentValue: 22.0, targetValue: 25.0, targetDate: Date().addingTimeInterval(86400 * 14), createdAt: Date()),
            Goal(id: UUID(), chapterId: chapterId, type: "Filantropia", title: "Cestas Básicas", description: "Doação para instituição", currentValue: 65.0, targetValue: 50.0, targetDate: Date().addingTimeInterval(86400 * 20), createdAt: Date())
        ]
    }
    
    public func updateProgress(goalId: UUID, newCurrentValue: Double) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
