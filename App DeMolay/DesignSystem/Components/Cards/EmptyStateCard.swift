import SwiftUI

enum CardType {
    case event
    case goal
    case committee
    case member
    case task
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
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhum evento agendado")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)
                        
                    case .goal:
                        Image(systemName: "target")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhuma meta definida")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)
                        
                    case .committee:
                        Image(systemName: "person.2.fill")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhuma comissão criada")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)
                        
                    case .member:
                        Image(systemName: "person.fill.xmark")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Nenhum membro encontrado")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)
                        
                    case .task:
                        Image(systemName: "checklist.checked")
                            .font(Typography.title3)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Tudo em dia!")
                            .font(Typography.title3)
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
                    Text("Adicione um membro e ele aparecerá aqui.")
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    
                case .task:
                    Text("Crie uma tarefa e ela aparecerá aqui.")
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
                    Text("Adicionar membro")
                case .task:
                    Text("Criar tarefa")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Spacing.md)
        .background(Theme.backgroundSecondary)
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
