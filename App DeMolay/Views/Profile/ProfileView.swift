import SwiftUI
import Auth

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showLeaveChapterAlert = false
    @State private var showDeleteAccountAlert = false
    
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
                            
                            // Ações da Conta
                            VStack(spacing: Spacing.md) {
                                Button(action: {
                                    showLeaveChapterAlert = true
                                }) {
                                    Text("Sair do Capítulo")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                
                                Button(action: {
                                    Task {
                                        await authViewModel.signOut()
                                    }
                                }) {
                                    Text("Sair da Conta")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                
                                Button(action: {
                                    showDeleteAccountAlert = true
                                }) {
                                    Text("Excluir Conta")
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(Theme.destructive)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.bottom, Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sair do Capítulo", isPresented: $showLeaveChapterAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Sair", role: .destructive) {
                    Task {
                        await authViewModel.leaveChapter()
                    }
                }
            } message: {
                Text("Tem certeza que deseja sair do seu Capítulo atual? Você precisará ser aprovado novamente ao entrar em um novo.")
            }
            .alert("Excluir Conta", isPresented: $showDeleteAccountAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Excluir", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Esta ação é irreversível. Todos os seus dados serão apagados e você perderá o acesso ao app.")
            }
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
