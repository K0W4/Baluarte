import SwiftUI

/// O símbolo grande que abre uma tela de estado — esperando aprovação, pedido enviado,
/// convite, recusa.
///
/// Existe por causa do Dynamic Type. Os seis usos que substitui escreviam
/// `.font(.system(size: 44))` e derivados: tamanho em pontos não escala, então quem
/// aumenta o texto via o título triplicar enquanto o ícone continua do mesmo tamanho — e,
/// nas telas sem rolagem, o ícone fixo ainda come a altura de que o texto precisava.
/// `@ScaledMetric` faz o símbolo crescer junto, na proporção do estilo de texto de que ele
/// é vizinho.
///
/// É sempre decorativo: o título logo abaixo já diz o que ele ilustra, e anunciar
/// "ampulheta círculo preenchido" antes disso só atrasa quem usa VoiceOver.
public struct HeroIcon: View {
    private let systemName: String
    private let tint: Color
    @ScaledMetric private var size: CGFloat

    public init(_ systemName: String, size: CGFloat = 56, tint: Color = Theme.accent) {
        self.systemName = systemName
        self.tint = tint
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    public var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}
