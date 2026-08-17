import SwiftUI

public struct SmartSummaryCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = SmartSummaryViewModel()
    @State private var isExpanded = false
    let chapterId: UUID
    
    public init(chapterId: UUID) {
        self.chapterId = chapterId
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            headerSection
            contentSection
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                        .stroke(
                            viewModel.generatedSummary.isEmpty ? Color.clear : Theme.accent.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .task {
            if viewModel.generatedSummary.isEmpty && !viewModel.isGenerating && viewModel.errorMessage == nil {
                await viewModel.generateSummary(chapterId: chapterId)
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .font(Typography.title3)
                .foregroundStyle(Theme.accent)
                .symbolEffect(.pulse, options: .repeating, isActive: viewModel.isGenerating && !reduceMotion)
                .accessibilityHidden(true)
            
            Text("Resumo Inteligente")
                .font(Typography.headline)
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            if viewModel.isGenerating {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.accent)
            } else if !viewModel.generatedSummary.isEmpty {
                Button(action: {
                    Task { await viewModel.generateSummary(chapterId: chapterId) }
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(Typography.headline)
                        .foregroundColor(Theme.accent)
                        .frame(minWidth: Spacing.minTouchTarget, minHeight: Spacing.minTouchTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Gerar resumo novamente")
            }
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if let error = viewModel.errorMessage {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(
                    error,
                    systemImage: viewModel.isUnavailableOnThisDevice ? "sparkles.slash" : "exclamationmark.triangle.fill"
                )
                .font(Typography.subheadline)
                .foregroundColor(viewModel.isUnavailableOnThisDevice ? Theme.textSecondary : Theme.destructive)

                // Sem o modelo no aparelho, tentar de novo nunca vai dar certo — oferecer
                // o botão é convidar a repetir uma coisa que não muda de resultado.
                if !viewModel.isUnavailableOnThisDevice {
                    Button("Tentar Novamente") {
                        Task { await viewModel.generateSummary(chapterId: chapterId) }
                    }
                    .font(Typography.caption1.weight(.bold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(minHeight: Spacing.minTouchTarget)
                }
            }
        } else if viewModel.generatedSummary.isEmpty && !viewModel.isGenerating {
            emptyStateSection
        } else if viewModel.isGenerating && viewModel.generatedSummary.isEmpty {
            generatingPlaceholder
        } else {
            summaryResultSection
        }
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Gere insights baseados nas metas, eventos e tarefas do seu Capítulo usando Apple Intelligence.")
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Button(action: {
                Task { await viewModel.generateSummary(chapterId: chapterId) }
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "sparkles")
                    Text("Gerar Resumo")
                }
                .font(Typography.headline)
                .foregroundColor(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Theme.accent)
                .cornerRadius(Spacing.cornerRadius)
            }
        }
    }
    
    private var generatingPlaceholder: some View {
        HStack(spacing: Spacing.xs) {
            Text("Analisando dados do Capítulo")
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Text(verbatim: "...")
                .font(Typography.subheadline)
                .foregroundColor(Theme.accentText)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: viewModel.isGenerating)
        }
    }
    
    private var summaryResultSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(viewModel.generatedSummary)
                .font(Typography.body)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : 6)
                .contentTransition(.interpolate)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.generatedSummary)
            
            if viewModel.generatedSummary.count > 300 {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Text(isExpanded ? "Ver menos" : "Ver mais")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}
