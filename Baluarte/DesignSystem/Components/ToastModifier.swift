import SwiftUI

enum ToastStyle {
    case success
    case error

    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success: return Theme.success
        case .error: return Theme.destructive
        }
    }

    // A refusal that disappears on its own is a refusal the person may never read,
    // and it is the one message they most need. Success can fade; failure waits.
    var autoDismissAfter: TimeInterval? {
        switch self {
        case .success: return 3
        case .error: return nil
        }
    }

    var accessibilityPrefix: String {
        switch self {
        case .success: return String(localized: "Sucesso")
        case .error: return String(localized: "Erro")
        }
    }
}

struct ToastBanner: View {
    let message: String
    let style: ToastStyle
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: style.iconName)
                .foregroundColor(style.tint)
                .font(Typography.body)

            Text(message)
                .font(Typography.body)
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(minHeight: Spacing.minTouchTarget)
        .background(Theme.backgroundPrimary)
        .cornerRadius(Spacing.cornerRadius)
        .shadow(color: Theme.textPrimary.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style.accessibilityPrefix): \(message)")
        .accessibilityHint(String(localized: "Toque duas vezes para dispensar."))
        .accessibilityAddTraits(.isButton)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let style: ToastStyle

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    ToastBanner(message: message, style: style, onDismiss: dismiss)
                        .padding(.top, Spacing.xl)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)

                    Spacer()
                }
                .onAppear(perform: scheduleAutoDismiss)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }

    private func scheduleAutoDismiss() {
        guard let delay = style.autoDismissAfter else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isPresented else { return }
            dismiss()
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, style: ToastStyle = .success) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, style: style))
    }
}
