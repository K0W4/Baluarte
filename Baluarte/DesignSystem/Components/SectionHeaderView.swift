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
                // Sem isto o rotor de cabeçalhos do VoiceOver fica vazio, e chegar em
                // "Comissões" na tela inicial exige varrer evento por evento e meta por
                // meta. Uma linha, seis telas.
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if let actionIcon = actionIcon, let action = action {
                Button(action: {
                    HapticManager.shared.impact(style: .light)
                    action()
                }) {
                    Image(systemName: actionIcon)
                        .font(Typography.title2)
                        .foregroundColor(Theme.accent)
                        .frame(minWidth: Spacing.minTouchTarget, minHeight: Spacing.minTouchTarget)
                        .contentShape(Rectangle())
                }
                // Uma string vazia não é ausência de rótulo: ela substitui o nome que a
                // SwiftUI derivaria do símbolo, e o botão passa a se anunciar como "botão"
                // e nada mais.
                .modifier(OptionalAccessibilityText(label: actionLabel, hint: actionHint))
            }
        }
    }
}

/// Aplica rótulo e dica só quando existem, em vez de sobrescrever com string vazia.
private struct OptionalAccessibilityText: ViewModifier {
    let label: LocalizedStringKey?
    let hint: LocalizedStringKey?

    @ViewBuilder
    func body(content: Content) -> some View {
        switch (label, hint) {
        case let (label?, hint?):
            content.accessibilityLabel(label).accessibilityHint(hint)
        case let (label?, nil):
            content.accessibilityLabel(label)
        case let (nil, hint?):
            content.accessibilityHint(hint)
        case (nil, nil):
            content
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
