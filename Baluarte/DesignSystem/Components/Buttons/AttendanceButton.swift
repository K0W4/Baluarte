import SwiftUI

/// Confirmar presença é a ação mais frequente do app, e por isso é a que mais precisa
/// dizer, de relance, se ainda há algo a fazer.
///
/// **Por confirmar** é a ação: preenchida com o vermelho da Ordem, texto e ícone em branco.
/// **Confirmada** é estado: contorno neutro, com o visto em verde — que só volta a
/// funcionar sobre fundo neutro. Verde sobre vermelho preenchido era o par que desaparece
/// para quem tem daltonismo vermelho-verde, e ainda invertia a hierarquia: o trabalho
/// terminado gritava mais alto que o pendente.
///
/// Os dois estados vivem num estilo só, e não em dois que se substituem: trocar de
/// `ButtonStyle` troca a identidade da view e o resultado é um corte seco. Com um estilo
/// que interpola preenchimento, contorno e cor de texto, a mudança é contínua — e o
/// símbolo troca com `.replace`, que é a transição que o próprio iOS usa.
public struct AttendanceButton: View {
    private let isConfirmed: Bool
    private let title: String
    private let action: () -> Void

    public init(isConfirmed: Bool, title: String, action: @escaping () -> Void) {
        self.isConfirmed = isConfirmed
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isConfirmed ? "checkmark.circle.fill" : "person.crop.circle.badge.plus")
                    .foregroundColor(isConfirmed ? Theme.success : Theme.onAccent)
                    .frame(width: 24, height: 24)
                    .contentTransition(.symbolEffect(.replace))

                Text(isConfirmed ? "Presença confirmada" : "Confirmar presença")
                    .contentTransition(.opacity)
            }
        }
        .buttonStyle(AttendanceButtonStyle(isConfirmed: isConfirmed))
        .accessibilityLabel(
            isConfirmed
                ? "Cancelar presença no evento \(title)"
                : "Confirmar presença no evento \(title)"
        )
    }
}

private struct AttendanceButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    let isConfirmed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
            .padding(.vertical, Spacing.xxs)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(stroke, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
            // Confirmar presença é otimista: o botão vira antes de o servidor responder, e
            // volta sozinho se ele recusar. Sem a animação, essa volta é um piscar que a
            // pessoa não consegue ler.
            .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: isConfirmed)
    }

    private var foreground: Color {
        guard isEnabled else { return Theme.textSecondary }
        return isConfirmed ? Theme.textPrimary : Theme.onAccent
    }

    private var background: Color {
        guard isEnabled else { return Theme.backgroundTertiary }
        return isConfirmed ? Theme.backgroundTertiary : Theme.accent
    }

    private var stroke: Color {
        isConfirmed || !isEnabled ? Theme.border : .clear
    }
}
