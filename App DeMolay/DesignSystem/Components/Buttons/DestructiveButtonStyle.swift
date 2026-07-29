import SwiftUI

public struct DestructiveButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundColor(Theme.destructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Theme.backgroundTertiary)
            .clipShape(Capsule())
            .overlay(
                RoundedRectangle(cornerRadius: .greatestFiniteMagnitude)
                    .stroke(Theme.destructive.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
