import SwiftUI

public struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isInitialState = true

    @ViewBuilder
    public func body(content: Content) -> some View {
        if isLoading && reduceMotion {
            // Quatro faixas de luz varrendo a tela sem parar, em todo carregamento e em
            // toda dispensa de folha, é exatamente o que "Reduzir Movimento" existe para
            // desligar. O esqueleto continua; o brilho é que sai.
            content
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
        } else if isLoading {
            content
                .redacted(reason: .placeholder)
                .overlay(
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Theme.backgroundSecondary,
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 3)
                        .offset(x: isInitialState ? -proxy.size.width * 1.5 : proxy.size.width * 1.5)
                    }
                    .mask(content.redacted(reason: .placeholder))
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isInitialState = false
                    }
                }
                .allowsHitTesting(false)
        } else {
            content
        }
    }
}

public extension View {
    func skeleton(isLoading: Bool) -> some View {
        modifier(ShimmerModifier(isLoading: isLoading))
    }
}
