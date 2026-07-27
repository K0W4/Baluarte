import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "shield.lefthalf.filled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Theme.accent)
                        
                        Text("App DeMolay")
                            .font(Typography.largeTitle)
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(Typography.caption1)
                            .foregroundColor(Theme.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Login Buttons
                    VStack(spacing: Spacing.md) {
                        if case .loading = authViewModel.state {
                            ProgressView()
                                .tint(Theme.accent)
                                .frame(height: 50)
                        } else {
                            Button(action: {
                                Task {
                                    await authViewModel.signInWithApple()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 20))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    Text("Continuar com Apple")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundColor(Theme.textPrimary)
                                .background(Theme.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    
                    HStack {
                        Rectangle().fill(Theme.border).frame(height: 1)
                        Text("ou")
                            .font(Typography.caption1)
                            .foregroundColor(Theme.textSecondary)
                        Rectangle().fill(Theme.border).frame(height: 1)
                    }
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    
                    NavigationLink(destination: EmailAuthView()) {
                        Text("Entrar com E-mail")
                            .font(Typography.headline)
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
    }
}
