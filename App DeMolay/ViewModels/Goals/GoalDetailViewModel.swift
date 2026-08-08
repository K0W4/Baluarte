import Foundation
import SwiftUI

@Observable
@MainActor
public final class GoalDetailViewModel {
    public var title: String
    public var currentValue: String
    public var targetValue: String
    public var targetDate: Date
    public var isCompleted: Bool
    
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let goalService: GoalServiceProtocol
    private var goal: Goal
    
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(targetValue.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(currentValue.replacingOccurrences(of: ",", with: ".")) != nil
    }
    
    public var hasChanges: Bool {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let currentString = formatter.string(from: NSNumber(value: goal.currentValue)) ?? String(goal.currentValue)
        let targetString = formatter.string(from: NSNumber(value: goal.targetValue)) ?? String(goal.targetValue)
        
        let currentInputDouble = Double(currentValue.replacingOccurrences(of: ",", with: ".")) ?? 0
        let targetInputDouble = Double(targetValue.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        let normalizedCurrent = formatter.string(from: NSNumber(value: currentInputDouble)) ?? String(currentInputDouble)
        let normalizedTarget = formatter.string(from: NSNumber(value: targetInputDouble)) ?? String(targetInputDouble)
        
        return goal.title != title ||
               normalizedCurrent != currentString ||
               normalizedTarget != targetString ||
               (goal.targetDate ?? Date()) != targetDate
    }
    
    public init(goal: Goal, goalService: GoalServiceProtocol = Services.goal) {
        self.goal = goal
        self.goalService = goalService
        
        self.title = goal.title
        
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        self.currentValue = formatter.string(from: NSNumber(value: goal.currentValue)) ?? String(goal.currentValue)
        self.targetValue = formatter.string(from: NSNumber(value: goal.targetValue)) ?? String(goal.targetValue)
        
        self.targetDate = goal.targetDate ?? Date()
        self.isCompleted = goal.isCompleted
    }
    
    public func saveChanges() async -> Bool {
        guard isValid && hasChanges else { return false }
        
        let target = Double(targetValue.replacingOccurrences(of: ",", with: ".")) ?? 0
        let current = Double(currentValue.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        guard target > 0 else {
            errorMessage = String(localized: "A meta alvo deve ser maior que zero.")
            return false
        }
        
        guard current >= 0 else {
            errorMessage = String(localized: "O valor atual não pode ser negativo.")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        var updatedGoal = goal
        updatedGoal.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGoal.currentValue = current
        updatedGoal.targetValue = target
        updatedGoal.targetDate = targetDate
        
        do {
            try await goalService.updateGoal(updatedGoal)
            self.goal = updatedGoal
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = String(localized: "Erro ao atualizar a meta.")
            isLoading = false
            return false
        }
    }
    
    public func completeGoal() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        var updatedGoal = goal
        updatedGoal.isCompleted = true
        updatedGoal.completedAt = Date()
        
        do {
            try await goalService.updateGoal(updatedGoal)
            self.goal = updatedGoal
            self.isCompleted = true
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = String(localized: "Erro ao concluir a meta.")
            isLoading = false
            return false
        }
    }
    
    public func deleteGoal() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await goalService.deleteGoal(goalId: goal.id)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = String(localized: "Erro ao excluir a meta.")
            isLoading = false
            return false
        }
    }
}
