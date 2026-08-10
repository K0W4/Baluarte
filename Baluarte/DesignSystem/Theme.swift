import SwiftUI

public struct Theme {
    public static let backgroundPrimary = Color(UIColor.systemBackground)
    public static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    public static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)

    public static let textPrimary = Color(UIColor.label)
    public static let textSecondary = Color(UIColor.secondaryLabel)
    public static let textTertiary = Color(UIColor.tertiaryLabel)

    /// O vermelho da Ordem, igual nos dois modos. É cor de **preenchimento** e de glifo
    /// grande: fundo de botão, círculo do dia selecionado, ícone. Como não muda, o branco
    /// por cima continua valendo a 5,51:1.
    ///
    /// Referencia o asset pelo nome, e não `Color.accentColor`: aquele não é a cor do
    /// catálogo, é o `tint` que estiver valendo no ambiente. Como o app passou a tingir com
    /// `accentText`, `Color.accentColor` arrastava junto todo preenchimento que devia
    /// continuar no vermelho da Ordem — os botões primários saíam na variante clara.
    public static let accent = Color("AccentColor")

    /// A mesma marca, na versão que dá para **ler**. Usada quando o destaque é texto ou
    /// ícone fino: `#C72B2B` sobre card escuro dá 3,09:1 e reprova o piso de 4,5:1 para
    /// texto normal, e clarear o preenchimento derrubaria o branco em cima dele. Separar
    /// por função resolve os dois lados sem mexer na identidade.
    ///
    /// É esta que o `.tint` do app usa, de propósito: o padrão precisa ser o legível, para
    /// que um botão novo nasça certo. O preenchimento é que é a exceção explícita.
    public static let accentText = Color("AccentText")

    public static let onAccent = Color.white

    public static let destructive = Color(UIColor.systemRed)
    public static let success = Color(UIColor.systemGreen)
    public static let warning = Color(UIColor.systemOrange)

    public static let border = Color(UIColor.separator)
    public static let cardBackground = Color(UIColor.secondarySystemBackground)

    public static let progressLowEnd = Color(UIColor.systemPink)
    public static let progressMediumEnd = Color(UIColor.systemYellow)
    public static let progressHighEnd = Color(UIColor.systemMint)
    public static let progressAdvancedEnd = Color(UIColor.systemBlue)
}

public struct CardButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
