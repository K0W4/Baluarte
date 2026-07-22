import SwiftUI

public struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    @State private var isInitialState = true
    
    public func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .overlay(
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.15),
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
