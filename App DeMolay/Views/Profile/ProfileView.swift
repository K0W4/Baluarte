import SwiftUI
import Auth

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showLeaveChapterAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showEditProfile = false
    @State private var showJoinRequests = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                if case let .authenticated(user, profile) = authViewModel.state {
                    List {
                        Section {
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(Theme.accent)
                                
                                Text(profile?.fullName ?? user.email ?? "Membro DeMolay")
                                    .font(Typography.title1)
                                    .foregroundColor(Theme.textPrimary)

                                if let cid = profile?.cid {
                                    Text("ID: \(cid)")
                                        .font(Typography.callout)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        Section {
                            ProfileInfoRow(icon: "shield.fill", title: "Nível de Acesso", value: authViewModel.accessLevel.displayName)
                            if let birthdate = profile?.birthdate {
                                ProfileInfoRow(icon: "calendar", title: "Data de Nascimento", value: birthdate.formatted(.dateTime.day().month(.twoDigits).year()))
                            }
                            ProfileInfoRow(icon: "star.fill", title: "Cargo", value: authViewModel.activeMembership?.role ?? "Sem Cargo")
                        } header: {
                            Text("Informações")
                        }
                        
                        if let chapterId = authViewModel.currentChapterId {
                            Section {
                                Button(action: { showJoinRequests = true }) {
                                    HStack(spacing: Spacing.md) {
                                        Image(systemName: "person.badge.clock")
                                            .foregroundColor(Theme.textPrimary)
                                            .frame(width: 24)
                                        Text("Solicitações de entrada")
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(Typography.footnote)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                }
                                .accessibilityHint("Abre a fila de quem pediu para entrar no Capítulo")
                            } header: {
                                Text("Administração")
                            }
                            .requires(.reviewJoinRequests)
                            .sheet(isPresented: $showJoinRequests) {
                                JoinRequestsView(chapterId: chapterId)
                            }
                        }

                        Section {
                            Button(action: {
                                showLeaveChapterAlert = true
                            }) {
                                Text("Sair do capítulo")
                                    .foregroundColor(Theme.textPrimary)
                            }
                            
                            Button(action: {
                                Task {
                                    await authViewModel.signOut()
                                }
                            }) {
                                Text("Sair da conta")
                                    .foregroundColor(Theme.textPrimary)
                            }
                            
                            Button(action: {
                                showDeleteAccountAlert = true
                            }) {
                                Text("Excluir conta")
                                    .foregroundColor(Theme.destructive)
                            }
                        } header: {
                            Text("Ações da Conta")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
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
                    .accessibilityLabel("Editar perfil")
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if case let .authenticated(_, profile) = authViewModel.state, let profile = profile {
                    EditProfileView(profile: profile)
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
                Text("Tem certeza que deseja sair do seu Capítulo atual? Você deixará de ver os eventos, metas e tarefas dele, mas poderá entrar em outro Capítulo quando quiser.")
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
                .foregroundColor(Theme.textPrimary)
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
