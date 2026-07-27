import SwiftUI
import Auth

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                if case let .authenticated(user, member) = authViewModel.state {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Avatar and Basic Info
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(Theme.accent)
                                
                                Text(member?.fullName ?? user.email ?? "Membro DeMolay")
                                    .font(Typography.title1)
                                    .foregroundColor(Theme.textPrimary)
                                
                                if let cid = member?.cid {
                                    Text("ID: \(cid)")
                                        .font(Typography.callout)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                            .padding(.top, Spacing.xl)
                            
                            // Info Cards
                            VStack(spacing: Spacing.md) {
                                ProfileInfoRow(icon: "shield.fill", title: "Nível de Acesso", value: member?.accessLevel ?? "Padrão")
                                if let role = member?.role {
                                    ProfileInfoRow(icon: "star.fill", title: "Cargo", value: role)
                                }
                            }
                            .padding(Spacing.lg)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(12)
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            
                            Spacer(minLength: 40)
                            
                            // Logout Button
                            Button(action: {
                                Task {
                                    await authViewModel.signOut()
                                }
                            }) {
                                Text("Sair da Conta")
                                    .font(Typography.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Theme.backgroundSecondary)
                                    .foregroundColor(Theme.destructive)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.bottom, Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .frame(width: 24)
            
            Text(title)
                .font(Typography.body)
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(Typography.callout)
                .foregroundColor(Theme.textSecondary)
        }
    }
}
