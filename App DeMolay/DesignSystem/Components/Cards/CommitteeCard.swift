import SwiftUI

public struct CommitteeCard: View {
    let committee: Committee
    let tasks: [ChapterTask]
    
    public init(committee: Committee, tasks: [ChapterTask]) {
        self.committee = committee
        self.tasks = tasks.filter { !$0.isCompleted }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.accent)
                    .font(Typography.headline)
                
                Text(committee.name)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(Typography.headline)
                    .foregroundColor(.accent)
            }
            
            Divider()
                .background(Theme.textSecondary)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if tasks.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.accent)
                        Text("Tudo em dia!")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(Spacing.xxs)
                } else {
                    ForEach(tasks.prefix(3)) { task in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "circle")
                                .foregroundColor(Theme.textSecondary)
                                .font(Typography.headline)
                            
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(task.title)
                                    .font(Typography.subheadline)
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)
                                
                                if let due = task.dueDate {
                                    Text(dueDateString(from: due))
                                        .font(Typography.caption1)
                                        .foregroundColor(due < Date() ? .red : Theme.textSecondary)
                                }
                            }
                        }
                    }
                    
                    if tasks.count > 3 {
                        Text("+ \(tasks.count - 3) pendentes")
                            .font(Typography.caption2)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.accent)
        )
    }
    
    private func dueDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
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
