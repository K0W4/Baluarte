import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.success)
                            .font(Typography.body)
                        
                        Text(message)
                            .font(Typography.body)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Theme.backgroundPrimary)
                    .cornerRadius(Spacing.cornerRadius)
                    .shadow(color: Theme.textPrimary.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.top, Spacing.xl)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}
