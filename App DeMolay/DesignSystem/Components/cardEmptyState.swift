//
//  cardEmptyState.swift
//  App DeMolay
//
//  Created by Gabriel Kowaleski on 15/07/26.
//

import SwiftUI

enum CardType {
    case event
    case goal
    case committee
}

struct CardEmptyState: View {
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
        CardEmptyState(cardType: .event)
        
        CardEmptyState(cardType: .goal)
        
        CardEmptyState(cardType: .committee)
    }
    .padding(Spacing.screenEdgePadding)
}
