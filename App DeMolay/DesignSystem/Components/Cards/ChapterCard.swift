import SwiftUI

public struct ChapterCard: View {
    let chapter: Chapter

    public init(chapter: Chapter) {
        self.chapter = chapter
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(chapter.name)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text("Capítulo nº \(chapter.number)")
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer(minLength: Spacing.xs)

            Image(systemName: "chevron.right")
                .font(Typography.body)
                .foregroundColor(Theme.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chapter.name), Capítulo número \(chapter.number)")
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
}

#Preview {
    ChapterCard(
        chapter: Chapter(
            id: UUID(),
            name: "Capítulo Exemplo",
            number: 42,
            currentTermStart: nil,
            currentTermEnd: nil,
            createdAt: nil
        )
    )
    .padding()
    .background(Theme.backgroundPrimary)
}
