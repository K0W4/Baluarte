import SwiftUI
import Auth

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showLeaveChapterAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                if case let .authenticated(user, member) = authViewModel.state {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
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
                            
                            VStack(spacing: Spacing.md) {
                                ProfileInfoRow(icon: "shield.fill", title: "Nível de Acesso", value: member?.accessLevel ?? "Padrão")
                                Divider()
                                    .padding(.leading, 40)
                                if let birthdate = member?.birthdate {
                                    ProfileInfoRow(icon: "calendar", title: "Data de Nascimento", value: birthdate.formatted(.dateTime.day().month(.twoDigits).year()))
                                    Divider()
                                        .padding(.leading, 40)
                                }
                                ProfileInfoRow(icon: "star.fill", title: "Cargo", value: member?.role ?? "Sem Cargo")
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
                                    Text("Sair do capítulo")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                
                                Button(action: {
                                    Task {
                                        await authViewModel.signOut()
                                    }
                                }) {
                                    Text("Sair da conta")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                
                                Button(action: {
                                    showDeleteAccountAlert = true
                                }) {
                                    Text("Excluir conta")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(DestructiveButtonStyle())
                            }
                            .padding(.horizontal, Spacing.screenEdgePadding)
                            .padding(.bottom, Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Meu perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditProfile = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if case let .authenticated(_, member) = authViewModel.state, let member = member {
                    EditProfileView(member: member)
                }
            }
            .alert("Sair do capítulo", isPresented: $showLeaveChapterAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Sair", role: .destructive) {
                    Task {
                        await authViewModel.leaveChapter()
                    }
                }
            } message: {
                Text("Tem certeza que deseja sair do seu Capítulo atual? Você precisará ser aprovado novamente ao entrar em um novo.")
            }
            .alert("Excluir conta", isPresented: $showDeleteAccountAlert) {
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
