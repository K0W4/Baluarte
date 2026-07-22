import SwiftUI

public enum CardType {
    case event
    case goal
    case committee
    case member
    case task
    
    var icon: String {
        switch self {
        case .event: return "calendar.badge.exclamationmark"
        case .goal: return "target"
        case .committee: return "person.2.fill"
        case .member: return "person.fill.xmark"
        case .task: return "checklist.checked"
        }
    }
    
    var title: String {
        switch self {
        case .event: return "Nenhum evento agendado"
        case .goal: return "Nenhuma meta definida"
        case .committee: return "Nenhuma comissão criada"
        case .member: return "Nenhum membro encontrado"
        case .task: return "Tudo em dia!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .event: return "Agende um evento e ele aparecerá aqui."
        case .goal: return "Defina uma meta e ela aparecerá aqui."
        case .committee: return "Crie uma comissão e ela aparecerá aqui."
        case .member: return "Adicione um membro e ele aparecerá aqui."
        case .task: return "Crie uma tarefa e ela aparecerá aqui."
        }
    }
    
    var buttonText: String {
        switch self {
        case .event: return "Agendar evento"
        case .goal: return "Definir meta"
        case .committee: return "Criar comissão"
        case .member: return "Adicionar membro"
        case .task: return "Criar tarefa"
        }
    }
}

public struct EmptyStateCard: View {
    let cardType: CardType
    
    public init(cardType: CardType) {
        self.cardType = cardType
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
            
            Button {
            } label: {
                Text(cardType.buttonText)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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
