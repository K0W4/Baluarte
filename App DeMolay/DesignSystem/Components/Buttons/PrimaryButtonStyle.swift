import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundColor(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Theme.backgroundTertiary)
            .clipShape(Capsule())
            .overlay(
                RoundedRectangle(cornerRadius: .greatestFiniteMagnitude)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

