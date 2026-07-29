import SwiftUI

public struct SmartSummaryCard: View {
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            viewModel.generatedSummary.isEmpty ? Color.clear : Theme.accent.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var headerSection: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "apple.intelligence")
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .symbolEffect(.pulse, options: .repeating, isActive: viewModel.isGenerating)
            
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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if let error = viewModel.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(Typography.subheadline)
                .foregroundColor(Theme.destructive)
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
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Theme.accent)
                .cornerRadius(12)
            }
        }
    }
    
    private var generatingPlaceholder: some View {
        HStack(spacing: Spacing.xs) {
            Text("Analisando dados do Capítulo")
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Text("...")
                .font(Typography.subheadline)
                .foregroundColor(Theme.accent)
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
            
            if viewModel.generatedSummary.count > 200 {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Text(isExpanded ? "Ver menos" : "Ver mais")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.accent)
                }
            }
            
            HStack(spacing: Spacing.xs) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 10))
                Text("Gerado por Apple Intelligence")
                    .font(Typography.caption2)
            }
            .foregroundColor(Theme.textTertiary)
            .padding(.top, Spacing.xs)
        }
    }
}
