import SwiftUI

public struct CompletedGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: HomeViewModel
    
    @State private var selectedGoal: Goal?
    
    private var groupedGoals: [(String, [Goal])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        
        var dict: [String: [Goal]] = [:]
        
        for goal in viewModel.completedGoals {
            let date = goal.completedAt ?? goal.targetDate ?? goal.createdAt
            let year = formatter.string(from: date)
            let month = Calendar.current.component(.month, from: date)
            let semester = month <= 6 ? 1 : 2
            
            let key = "\(year).\(semester)"
            dict[key, default: []].append(goal)
        }
        
        let sortedKeys = dict.keys.sorted(by: >)
        return sortedKeys.compactMap { key in dict[key].map { (key, $0) } }
    }
    
    private func formatSemesterKey(_ key: String) -> String {
        let components = key.split(separator: ".")
        guard components.count == 2,
              let year = components.first,
              let semester = components.last else {
            return key
        }
        return "\(semester)º Semestre de \(year)"
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if viewModel.completedGoals.isEmpty {
                        // Sem a closure vazia: ela não é `nil`, então o cartão desenhava um
                        // botão "Definir meta" com estilo primário que não fazia nada — e o
                        // VoiceOver o anunciava como acionável.
                        EmptyStateCard(cardType: .goal)
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.top, Spacing.md)
                    } else {
                        ForEach(groupedGoals, id: \.0) { section in
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text(formatSemesterKey(section.0))
                                    .font(Typography.headline)
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.horizontal, Spacing.screenEdgePadding)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.xs) {
                                        ForEach(section.1) { goal in
                                            ProgressRingCard(goal: goal)
                                                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: Spacing.xs)
                                                .onTapGesture {
                                                    selectedGoal = goal
                                                }
                                        }
                                    }
                                    .scrollTargetLayout()
                                }
                                .contentMargins(.horizontal, Spacing.screenEdgePadding, for: .scrollContent)
                                .scrollTargetBehavior(.viewAligned)
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.screenEdgePadding)
            }
            .scrollIndicators(.hidden)
            .background(Theme.backgroundPrimary)
            .navigationTitle("Metas Concluídas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.accentText)
                    }
                    .accessibilityLabel("Fechar")
                }
            }
            .sheet(item: $selectedGoal, onDismiss: {
                Task {
                    await viewModel.loadData(showLoading: false)
                }
            }) { goal in
                GoalDetailView(goal: goal)
            }
        }
    }
}
