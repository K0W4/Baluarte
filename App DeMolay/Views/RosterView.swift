import SwiftUI

struct RosterView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: Spacing.md) {
                    Text("Membros e Gestão")
                        .font(Typography.body)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.screenEdgePadding)
            }
            .navigationTitle("Nominata")
        }
    }
}

#Preview {
    RosterView()
}
