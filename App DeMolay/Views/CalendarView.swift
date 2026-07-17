import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: Spacing.md) {
                    Text("Eventos e Reuniões")
                        .font(Typography.body)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.screenEdgePadding)
            }
            .navigationTitle("Calendário")
        }
    }
}

#Preview {
    CalendarView()
}
