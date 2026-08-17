import SwiftUI

/// A ação que não tem volta.
///
/// O que separa esta da ação principal é **forma, não matiz**: o primário é preenchido com
/// o vermelho da Ordem, este é contorno sobre fundo transparente. `Theme.accent` e
/// `Theme.destructive` contrastam só 1,62:1 entre si — enquanto os dois disputavam a mesma
/// forma, a cor não decidia nada. Separados por preenchimento contra contorno, os dois
/// deixam de competir e o vermelho de sistema pode continuar sendo o que todo iPhone já
/// ensinou que ele é.
///
/// Preenchimento vermelho aqui, nunca: é o que faria a destruição voltar a parecer a ação
/// que o app quer que você tome.
public struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundColor(isEnabled ? Theme.destructive : Theme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
            .padding(.vertical, Spacing.xxs)
            .background(Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isEnabled ? Theme.destructive : Theme.border, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
