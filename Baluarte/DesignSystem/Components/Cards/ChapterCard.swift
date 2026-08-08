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
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(chapter.name)
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    if chapter.status == .dormant {
                        badge("Dormente", tint: Theme.textSecondary)
                    } else if !chapter.hasOwner {
                        badge("Sem administrador", tint: Theme.accent)
                    }
                }

                Text(subtitle)
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
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

    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(Typography.caption2)
            .foregroundColor(tint)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(Theme.backgroundTertiary)
            .clipShape(Capsule())
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
