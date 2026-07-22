import SwiftUI

public struct TaskCard: View {
    let task: ChapterTask
    let onToggle: () -> Void
    
    public init(task: ChapterTask, onToggle: @escaping () -> Void) {
        self.task = task
        self.onToggle = onToggle
    }
    
    public var body: some View {
        
        HStack(alignment: .top, spacing: Spacing.sm) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onToggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(Typography.title2)
                    .foregroundColor(task.isCompleted ? Theme.success : Theme.textSecondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Text(task.title)
                        .font(Typography.headline)
                        .foregroundColor(task.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                        .strikethrough(task.isCompleted, color: Theme.textSecondary)
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        Text(formatDate(dueDate))
                            .font(Typography.body)
                            .foregroundColor(isOverdue(dueDate) && !task.isCompleted ? Theme.destructive : Theme.textSecondary)
                    }
                }
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        date < Date()
    }
}
