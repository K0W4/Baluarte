import SwiftUI

public struct ErrorBannerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let message: String
    let onRetry: () -> Void
    let onDismiss: (() -> Void)?

    public init(
        message: String,
        onRetry: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.headline)
                    .foregroundColor(Theme.warning)
                
                // Sem limite de linhas: em tamanho de acessibilidade a explicação era
                // cortada com reticências, sem como expandir, justamente para quem mais
                // precisa dela.
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)


                Spacer()
                
                if let onDismiss {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Typography.caption1)
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Fechar alerta")
                }
            }
            
            Button {
                HapticManager.shared.impact(style: .medium)
                onRetry()
            } label: {
                Text("Tentar novamente")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityHint("Toca duas vezes para recarregar os dados")
        }
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                .stroke(Theme.warning.opacity(0.5), lineWidth: 1)
        )
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.isSummaryElement)
        // O banner nasce fora do ponto de foco — no login, acima do formulário, depois de
        // a pessoa tocar em entrar. Sem anúncio, o VoiceOver não dizia nada e ela tentava
        // de novo achando que o toque não tinha registrado.
        .onAppear { AccessibilityNotification.Announcement(message).post() }
    }
}

#Preview {
    VStack {
        Spacer()
        ErrorBannerView(
            message: String(localized: "Não foi possível carregar os dados. Verifique sua conexão."),
            onRetry: {},
            onDismiss: {}
        )
        .padding(.horizontal, Spacing.screenEdgePadding)
        Spacer()
    }
    .background(Theme.backgroundPrimary)
}
