import SwiftUI

public struct CommitteeCard: View {
    let committee: Committee
    let tasks: [ChapterTask]
    let onTaskToggled: ((UUID) -> Void)?
    
    public init(committee: Committee, tasks: [ChapterTask], onTaskToggled: ((UUID) -> Void)? = nil) {
        self.committee = committee
        self.tasks = tasks.filter { !$0.isCompleted }
        self.onTaskToggled = onTaskToggled
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Theme.textPrimary)
                    .font(Typography.headline)
                
                Text(committee.name)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(Typography.body)
                    .foregroundColor(Theme.accent)
            }
            
            Divider()
                .background(Theme.border)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if tasks.isEmpty {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Theme.success)
                            .font(Typography.headline)
                        
                        Text("Tudo em dia!")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textPrimary)
                            
                        Spacer()
                    }
                } else {
                    ForEach(tasks.prefix(3)) { task in
                        HStack(alignment: .center, spacing: Spacing.sm) {
                            Button(action: {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                onTaskToggled?(task.id)
                            }) {
                                Image(systemName: "circle")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Marcar tarefa \(task.title) como concluída")
                            
                            HStack(alignment: .center) {
                                Text(task.title)
                                    .font(Typography.subheadline)
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if let due = task.dueDate {
                                    Text(dueDateString(from: due))
                                        .font(Typography.caption1)
                                        .foregroundColor(due < Date() ? Theme.destructive : Theme.textSecondary)
                                }
                            }
                        }
                    }
                    
                    if tasks.count > 3 {
                        Button(action: {}) {
                            Text("Ver as \(tasks.count - 3) tarefas restantes")
                                .font(Typography.caption1)
                                .foregroundColor(Theme.accent)
                                .padding(.top, Spacing.xxs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border)
        )
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        return formatter
    }()
    
    private func dueDateString(from date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}

#Preview {
    let mockCommittee1 = Committee(id: UUID(), chapterId: UUID(), name: "Comissão de Sindicância", chairmanId: nil, createdAt: Date())
    let mockCommittee2 = Committee(id: UUID(), chapterId: UUID(), name: "Comissão de Hospitalaria", chairmanId: nil, createdAt: Date())
    let mockCommittee3 = Committee(id: UUID(), chapterId: UUID(), name: "Comissão de Finanças", chairmanId: nil, createdAt: Date())
    
    let mockTasks = [
        ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Entrevistar João", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(86400), createdAt: Date()),
        ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Solicitar documentos", description: "", isCompleted: false, dueDate: Date().addingTimeInterval(-86400), createdAt: Date()),
        ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Votar em plenário", description: "", isCompleted: false, dueDate: nil, createdAt: Date()),
        ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Extra task", description: "", isCompleted: false, dueDate: nil, createdAt: Date())
    ]
    
    return ScrollView {
        VStack(spacing: 16) {
            CommitteeCard(committee: mockCommittee1, tasks: mockTasks)
            CommitteeCard(committee: mockCommittee2, tasks: [])
            CommitteeCard(committee: mockCommittee3, tasks: Array(mockTasks.prefix(2)))
        }
        .padding()
    }
    .background(Color(UIColor.systemBackground))
    .preferredColorScheme(.dark)
}
