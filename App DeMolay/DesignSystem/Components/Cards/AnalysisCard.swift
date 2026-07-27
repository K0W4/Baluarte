import SwiftUI

struct AnalysisCard: View {
    let analysis: DisplayedAnalysis
    var onActionTapped: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Image(systemName: iconName)
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(analysis.title)
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Text(analysis.message)
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer(minLength: 0)
            
            if let actionLabel = analysis.suggestedActionLabel {
                Button {
                    onActionTapped?()
                } label: {
                    Text(actionLabel)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch analysis.category {
        case .membership: return "person.2.fill"
        case .structure: return "building.columns.fill"
        case .calendar: return "calendar.badge.exclamationmark"
        case .engagement: return "chart.line.uptrend.xyaxis"
        case .financial: return "dollarsign.circle.fill"
        }
    }
}

#Preview {
    ZStack {
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 16) {
                AnalysisCard(
                    analysis: DisplayedAnalysis(
                        rawAnalysis: RawAnalysis(
                            category: .calendar,
                            severity: .info,
                            contextData: [:],
                            fallbackTitle: "",
                            fallbackMessage: ""
                        ),
                        generatedTitle: "Planeje o Sucesso",
                        generatedMessage: "O 'Dia do DeMolay' já está no horizonte! Planejar essa data com antecedência garante uma atividade memorável e muito mais presença das nossas famílias.",
                        actionLabel: "Criar Evento"
                    )
                )
                
                AnalysisCard(
                    analysis: DisplayedAnalysis(
                        rawAnalysis: RawAnalysis(
                            category: .membership,
                            severity: .warning,
                            contextData: [:],
                            fallbackTitle: "",
                            fallbackMessage: ""
                        ),
                        generatedTitle: "Oportunidade de Renovação",
                        generatedMessage: "O Capítulo conta com 2 irmão(s) alcançando a maioridade neste semestre! É o momento perfeito para organizarmos uma iniciação e garantirmos novos líderes para nossa ordem.",
                        actionLabel: "Ver Membros"
                    )
                )
                
                AnalysisCard(
                    analysis: DisplayedAnalysis(
                        rawAnalysis: RawAnalysis(
                            category: .structure,
                            severity: .actionRequired,
                            contextData: [:],
                            fallbackTitle: "",
                            fallbackMessage: ""
                        ),
                        generatedTitle: "Potencialize sua Gestão",
                        generatedMessage: "Para envolver mais irmãos e alavancar nossos resultados, que tal estruturar a Comissão de Sindicância? Delegar tarefas é o segredo de um Capítulo dinâmico.",
                        actionLabel: "Criar Comissão"
                    )
                )
                
                AnalysisCard(
                    analysis: DisplayedAnalysis(
                        rawAnalysis: RawAnalysis(
                            category: .engagement,
                            severity: .warning,
                            contextData: [:],
                            fallbackTitle: "",
                            fallbackMessage: ""
                        ),
                        generatedTitle: "Acolhimento Fraternal",
                        generatedMessage: "Senti a falta de 2 irmão(s) nas últimas três reuniões. Uma mensagem amigável da Hospitalaria fará toda a diferença para mostrar que nos importamos com eles.",
                        actionLabel: nil
                    )
                )
            }
            .padding()
        }
    }
}
