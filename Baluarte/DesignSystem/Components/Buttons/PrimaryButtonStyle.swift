import SwiftUI

/// A ação principal da tela. Preenchida com o vermelho da Ordem — é o único lugar onde a
/// cor de marca vira superfície, e é por isso que ela existe.
///
/// Antes este estilo era idêntico ao secundário, pixel a pixel: mesma fonte, mesmo fundo
/// terciário, mesma cápsula, mesmo contorno. O app tinha a cor mais sinalizadora que
/// existe e não a usava em ação nenhuma — o vermelho aparecia só em chevron, ícone e nos
/// botões "Sair". O destaque afirmava "perigo" e nunca "faça isto".
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            // Branco sobre o vermelho da Ordem dá 5,51:1 nos dois modos. É o par que faz o
            // preenchimento poder continuar sendo a cor de marca sem variante por tema.
            .foregroundColor(isEnabled ? Theme.onAccent : Theme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
            .padding(.vertical, Spacing.xxs)
            .background(isEnabled ? Theme.accent : Theme.backgroundTertiary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isEnabled ? Color.clear : Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A alternativa. Contorno neutro, sem preenchimento: existe para não competir com a ação
/// principal, que é justamente o que os dois estilos faziam quando eram iguais.
public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundColor(isEnabled ? Theme.textPrimary : Theme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
            .padding(.vertical, Spacing.xxs)
            .background(Theme.backgroundTertiary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
