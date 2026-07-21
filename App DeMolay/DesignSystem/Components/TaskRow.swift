import SwiftUI

public struct TaskRow: View {
    let task: ChapterTask
    let onToggle: () -> Void
    
    public init(task: ChapterTask, onToggle: @escaping () -> Void) {
        self.task = task
        self.onToggle = onToggle
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Button {
                onToggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(Typography.title2)
                    .foregroundColor(task.isCompleted ? .accentColor : Theme.textSecondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(task.title)
                    .font(Typography.body)
                    .foregroundColor(Theme.textPrimary)
                    .strikethrough(task.isCompleted, color: Theme.textSecondary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(Typography.caption1)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
                
                if let dueDate = task.dueDate {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "calendar")
                        Text(formatDate(dueDate))
                    }
                    .font(Typography.caption2)
                    .foregroundColor(isOverdue(dueDate) && !task.isCompleted ? .red : Theme.textSecondary)
                    .padding(.top, Spacing.xxxs)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        date < Date()
    }
}
