import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundColor(Theme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
            .padding(.vertical, Spacing.xxs)
            .background(Theme.backgroundTertiary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundColor(isEnabled ? Theme.textPrimary : Theme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
            .padding(.vertical, Spacing.xxs)
            .background(Theme.backgroundTertiary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
