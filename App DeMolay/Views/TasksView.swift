import SwiftUI

struct TasksView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: Spacing.md) {
                    Text("Metas e Checklists")
                        .font(Typography.body)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.screenEdgePadding)
            }
            .navigationTitle("Tarefas")
        }
    }
}

#Preview {
    TasksView()
}
