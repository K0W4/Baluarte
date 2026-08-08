import SwiftUI

public extension View {
    /// Removes the affordance entirely. Use for purely additive controls — a "+" a
    /// member can never use is noise that costs every member a decision (Hick's Law).
    func requires(_ permission: Permission) -> some View {
        modifier(RequiresPermissionModifier(permission: permission))
    }

    /// Keeps the affordance visible but inert, with a VoiceOver-readable reason.
    /// Use where removing it would break comprehension of the surrounding layout.
    func gated(_ permission: Permission, reason: String) -> some View {
        modifier(GatedPermissionModifier(permission: permission, reason: reason))
    }
}

private struct RequiresPermissionModifier: ViewModifier {
    @Environment(\.permissions) private var permissions
    let permission: Permission

    @ViewBuilder
    func body(content: Content) -> some View {
        if permissions.can(permission) {
            content
        }
    }
}

private struct GatedPermissionModifier: ViewModifier {
    @Environment(\.permissions) private var permissions
    let permission: Permission
    let reason: String

    func body(content: Content) -> some View {
        let allowed = permissions.can(permission)
        return content
            .disabled(!allowed)
            .opacity(allowed ? 1 : 0.4)
            .accessibilityHint(allowed ? "" : reason)
    }
}
