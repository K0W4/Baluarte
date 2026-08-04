import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    var onFinish: (() -> Void)? = nil
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageSystemName: "crown.fill",
            title: "Gestão Descomplicada",
            description: "Acompanhe e organize todas as informações do seu Capítulo em um único lugar, de forma intuitiva e eficiente."
        ),
        OnboardingPage(
            imageSystemName: "calendar.badge.clock",
            title: "Calendário Inteligente",
            description: "Nunca mais perca um evento. Confirme presença, veja detalhes e mantenha os irmãos sempre informados."
        ),
        OnboardingPage(
            imageSystemName: "building.columns.fill",
            title: "Comissões Ativas",
            description: "Delegue tarefas e acompanhe o progresso de cada comissão em tempo real. O segredo do sucesso é a colaboração."
        ),
        OnboardingPage(
            imageSystemName: "apple.intelligence",
            title: "Análise Estratégica",
            description: "Deixe que a nossa Inteligência Artificial analise seus dados e gere insights valiosos e ações recomendadas para o crescimento do seu Capítulo."
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack {
                    Text("Passo \(currentPage + 1) de \(pages.count)")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, Spacing.md)
                        .accessibilityLabel("Passo \(currentPage + 1) de \(pages.count)")

                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingSlideView(page: pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(reduceMotion ? nil : .easeInOut, value: currentPage)

                    Button(action: {
                        HapticManager.shared.impact(style: .medium)

                        if currentPage < pages.count - 1 {
                            if reduceMotion {
                                currentPage += 1
                            } else {
                                withAnimation { currentPage += 1 }
                            }
                        } else {
                            onFinish?()
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Próximo" : "Começar Agora")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Pular") {
                        onFinish?()
                    }
                    .foregroundColor(Theme.textSecondary)
                    .opacity(currentPage < pages.count - 1 ? 1 : 0)
                    .disabled(currentPage == pages.count - 1)
                    .accessibilityHidden(currentPage == pages.count - 1)
                    .accessibilityHint("Pula a apresentação e vai para o acesso")
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
