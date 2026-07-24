import SwiftUI

public struct TaskCard: View {
    let task: ChapterTask
    let onToggle: () -> Void
    
    public init(task: ChapterTask, onToggle: @escaping () -> Void) {
        self.task = task
        self.onToggle = onToggle
    }
    
    public var body: some View {
        
        HStack(alignment: task.description.isEmpty ? .center : .top, spacing: Spacing.sm) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onToggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(Typography.title2)
                    .foregroundColor(task.isCompleted ? Theme.success : Theme.textSecondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .accessibilityLabel(task.isCompleted ? "Desmarcar tarefa \(task.title)" : "Marcar tarefa \(task.title) como concluída")
            
            VStack(alignment: .leading, spacing: task.isCompleted ? 0 : Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Text(task.title)
                        .font(Typography.headline)
                        .foregroundColor(task.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                        .strikethrough(task.isCompleted, color: Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let dueDate = task.dueDate, !task.isCompleted {
                        Text(formatDate(dueDate))
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                
                if !task.description.isEmpty && !task.isCompleted {
                    Text(task.description)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    private func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}
