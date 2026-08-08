import SwiftUI

struct InsightSectionCard: View {
    let insight: ConsolidatedInsight
    var onActionTapped: (() -> Void)? = nil
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            headerRow

            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if insight.category == .structure {
                        Text("Comissões Ausentes:")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textPrimary)
                        
                        ForEach(insight.items) { item in
                            Text("• \(item.title)")
                                .font(Typography.footnote)
                                .foregroundColor(Theme.textSecondary)
                        }
                    } else if insight.category == .calendar {
                        Text("Dias Obrigatórios Ausentes:")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textPrimary)
                        
                        ForEach(insight.items) { item in
                            Text("• \(item.title)")
                                .font(Typography.footnote)
                                .foregroundColor(Theme.textSecondary)
                        }
                    } else {
                        ForEach(insight.items) { item in
                            insightRow(item)
                        }
                    }
                }

                if let actionLabel = insight.primaryActionLabel, let onActionTapped {
                    Button {
                        onActionTapped()
                    } label: {
                        Text(actionLabel)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var headerRow: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: insight.iconName)
                    .font(Typography.headline)
                    .foregroundColor(severityColor)

                Text(insight.title)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text("\(insight.itemCount)")
                    .font(Typography.caption1.weight(.semibold))
                    .foregroundColor(Theme.backgroundPrimary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(severityColor)
                    .clipShape(Capsule())

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(Typography.caption1)
                    .foregroundColor(Theme.accent)
            }
        }
        .buttonStyle(.plain)
    }

    private func insightRow(_ item: DisplayedAnalysis) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(item.title)
                .font(Typography.subheadline)
                .foregroundColor(Theme.textPrimary)

            Text(item.message)
                .font(Typography.footnote)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)
        }
    }

    private var severityColor: Color {
        return Theme.textPrimary
    }
}
