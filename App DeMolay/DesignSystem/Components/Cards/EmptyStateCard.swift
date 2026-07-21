import SwiftUI

enum CardType {
    case event
    case goal
    case committee
    case member
}

struct EmptyStateCard: View {
    let cardType: CardType

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .center, spacing: Spacing.xs) {
                    switch cardType {
                    case .event:
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhum evento futuro")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)
                        
                    case .goal:
                        Image(systemName: "target")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhuma meta definida")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)
                        
                    case .committee:
                        Image(systemName: "person.2.fill")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhuma comissão criada")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)
                    case .member:
                        Image(systemName: "person.fill.xmark")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhum membro encontrado")
                            .font(Typography.title3)
                            .bold()
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                
                switch cardType {
                case .event:
                    Text("Agende um evento e ele aparecerá aqui.")
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    
                case .goal:
                    Text("Defina uma meta e ela aparecerá aqui.")
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    
                case .committee:
                    Text("Crie uma comissão e ela aparecerá aqui.")
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.textSecondary)
                case .member:
                    Text("Ajuste os filtros de busca para tentar novamente.")
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            Button {
            } label: {
                switch cardType {
                case .event:
                    Text("Agendar evento")
                case .goal:
                    Text("Definir meta")
                case .committee:
                    Text("Criar comissão")
                case .member:
                    Text("Limpar busca")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Spacing.md)
        .background(Theme.backgroundSecondary)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.accent, lineWidth: 1)
        )
    }

}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.xl) {
        EmptyStateCard(cardType: .event)
        
        EmptyStateCard(cardType: .goal)
        
        EmptyStateCard(cardType: .committee)
    }
    .padding(Spacing.screenEdgePadding)
}
