import SwiftUI

public enum CardType {
    case event
    case goal
    case committee
    case member
    case task
    case chapter
    case chapterRequests

    var icon: String {
        switch self {
        case .event: return "calendar.badge.exclamationmark"
        case .goal: return "target"
        case .committee: return "person.2.fill"
        case .member: return "person.fill.xmark"
        case .task: return "checklist.checked"
        case .chapter: return "building.2.crop.circle"
        case .chapterRequests: return "tray"
        }
    }

    var title: String {
        switch self {
        case .event: return String(localized: "Nenhum evento agendado")
        case .goal: return String(localized: "Nenhuma meta definida")
        case .committee: return String(localized: "Nenhuma comissão criada")
        case .member: return String(localized: "Nenhum membro encontrado")
        case .task: return String(localized: "Tudo em dia!")
        case .chapter: return String(localized: "Nenhum Capítulo cadastrado")
        case .chapterRequests: return String(localized: "Nenhum Capítulo solicitado")
        }
    }

    var subtitle: String {
        switch self {
        case .event: return String(localized: "Agende um evento e ele aparecerá aqui.")
        case .goal: return String(localized: "Defina uma meta e ela aparecerá aqui.")
        case .committee: return String(localized: "Crie uma comissão e ela aparecerá aqui.")
        case .member: return String(localized: "Adicione um membro e ele aparecerá aqui.")
        case .task: return String(localized: "Crie uma tarefa e ela aparecerá aqui.")
        case .chapter: return String(localized: "Crie o primeiro Capítulo para começar.")
        case .chapterRequests: return String(localized: "Quando alguém não encontrar o Capítulo dele no catálogo, o pedido aparece aqui.")
        }
    }

    var buttonText: String {
        switch self {
        case .event: return String(localized: "Agendar evento")
        case .goal: return String(localized: "Definir meta")
        case .committee: return String(localized: "Criar comissão")
        case .member: return String(localized: "Adicionar membro")
        case .task: return String(localized: "Criar tarefa")
        case .chapter: return String(localized: "Criar novo capítulo")
        case .chapterRequests: return String(localized: "Atualizar")
        }
    }
}

public struct EmptyStateCard: View {
    let cardType: CardType
    let action: (() -> Void)?
    
    public init(cardType: CardType, action: (() -> Void)? = nil) {
        self.cardType = cardType
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .center, spacing: Spacing.xs) {
                    Image(systemName: cardType.icon)
                        .font(Typography.title3)
                        .foregroundStyle(Theme.textPrimary)

                    Text(cardType.title)
                        .font(Typography.title3)
                        .foregroundStyle(Theme.textPrimary)
                }
                
                Text(cardType.subtitle)
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            if let action {
                Button {
                    action()
                } label: {
                    Text(cardType.buttonText)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cardType.title). \(cardType.subtitle)")
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Spacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            EmptyStateCard(cardType: .event)
            EmptyStateCard(cardType: .goal)
            EmptyStateCard(cardType: .committee)
            EmptyStateCard(cardType: .member)
            EmptyStateCard(cardType: .task)
        }
        .padding(Spacing.screenEdgePadding)
    }
}
