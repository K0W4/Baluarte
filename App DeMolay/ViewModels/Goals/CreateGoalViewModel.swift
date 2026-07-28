import Foundation
import SwiftUI

@Observable
@MainActor
public final class CreateGoalViewModel {
    public var title: String = ""
    public var targetValue: String = ""
    public var targetDate: Date = Date().addingTimeInterval(86400 * 30) // 30 dias de default
    
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let goalService: GoalServiceProtocol
    private let chapterId: UUID
    
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(targetValue.replacingOccurrences(of: ",", with: ".")) != nil
    }
    
    public init(chapterId: UUID, goalService: GoalServiceProtocol = Services.goal) {
        self.goalService = goalService
        self.chapterId = chapterId
    }
    
    public func saveGoal() async -> Bool {
        guard isValid else { return false }
        
        let target = Double(targetValue.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard target > 0 else {
            errorMessage = "A meta alvo deve ser maior que zero."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        let newGoal = Goal(
            id: UUID(),
            chapterId: chapterId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: nil,
            currentValue: 0,
            targetValue: target,
            targetDate: targetDate,
            createdAt: Date()
        )
        
        do {
            try await goalService.createGoal(newGoal)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = "Erro ao criar a meta. Tente novamente."
            isLoading = false
            return false
        }
    }
}
