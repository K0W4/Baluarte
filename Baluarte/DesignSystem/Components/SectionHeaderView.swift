import SwiftUI

public struct SectionHeaderView: View {
    public let title: LocalizedStringKey
    public let actionIcon: String?
    public let actionLabel: LocalizedStringKey?
    public let actionHint: LocalizedStringKey?
    public let action: (() -> Void)?
    
    public init(
        title: LocalizedStringKey,
        actionIcon: String? = "plus",
        actionLabel: LocalizedStringKey? = nil,
        actionHint: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionIcon = actionIcon
        self.actionLabel = actionLabel
        self.actionHint = actionHint
        self.action = action
    }
    
    public var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(Typography.title2)
                .bold()
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            if let actionIcon = actionIcon, let action = action {
                Button(action: {
                    HapticManager.shared.impact(style: .light)
                    action()
                }) {
                    Image(systemName: actionIcon)
                        .font(Typography.title2)
                        .foregroundColor(Theme.accent)
                        
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(actionLabel ?? "")
                .accessibilityHint(actionHint ?? "")
            }
        }
    }
}

#Preview {
    SectionHeaderView(
        title: "Eventos",
        actionLabel: "Adicionar evento",
        actionHint: "Toque duplo para adicionar",
        action: {}
    )
    .padding()
}
