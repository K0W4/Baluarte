import SwiftUI

public struct ChapterCard: View {
    let chapter: Chapter

    public init(chapter: Chapter) {
        self.chapter = chapter
    }

    private var accessibilityDescription: String {
        var parts = ["\(chapter.name), Capítulo número \(chapter.number)"]
        if let location = chapter.locationLabel { parts.append(location) }
        if chapter.status == .dormant {
            parts.append("Capítulo dormente")
        } else if !chapter.hasOwner {
            parts.append("Ainda sem administrador no app")
        }
        return parts.joined(separator: ", ")
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // A etiqueta desceu para a linha de baixo: ao lado do nome ela disputava a
            // largura com ele, e "Arquitetos do Oriente" virava "Arquitetos do Ori…".
            // Aqui o nome usa a linha inteira, e a etiqueta divide espaço com um texto
            // curto que pode truncar sem perder o que importa.
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(chapter.name)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    if chapter.status == .dormant {
                        badge("Dormente", tint: Theme.textSecondary)
                    } else if !chapter.hasOwner {
                        badge("Sem adm", tint: Theme.accentText)
                    }

                    Text(subtitle)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Spacing.xs)

            Image(systemName: "chevron.right")
                .font(Typography.body)
                .foregroundColor(Theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Toca duas vezes para entrar neste Capítulo")
        .accessibilityAddTraits(.isButton)
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    /// Contorno, não preenchimento — e as duas razões apontam para o mesmo lugar. É um
    /// estado, e a regra da casa é que preenchido é ação e contorno é estado. E o
    /// preenchimento era o que reprovava o contraste: a cápsula clareava o fundo para
    /// `#2C2C2E` e o texto da marca caía a **2,53:1** no escuro. Sobre o próprio cartão
    /// o mesmo texto mede 5,2:1, acima do piso de 4,5:1 que um caption2 exige.
    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(Typography.caption2)
            .foregroundColor(tint)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(tint.opacity(0.4), lineWidth: 1))
    }

    private var subtitle: String {
        if let location = chapter.locationLabel {
            return "nº \(chapter.number) · \(location)"
        }
        return "Capítulo nº \(chapter.number)"
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        ChapterCard(
            chapter: Chapter(id: UUID(), name: "Capítulo Exemplo", number: 42, uf: "RS", city: "Porto Alegre")
        )
        ChapterCard(
            chapter: Chapter(id: UUID(), name: "Capítulo Dormente", number: 7, uf: "RS", city: "Pelotas", status: .dormant)
        )
    }
    .padding()
    .background(Theme.backgroundPrimary)
}
