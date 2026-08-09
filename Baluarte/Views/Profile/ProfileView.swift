import SwiftUI
import Auth

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showLeaveChapterAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showEditProfile = false
    @State private var showJoinRequests = false
    @State private var showInvites = false
    @State private var showBootstrapQueue = false
    @State private var showPlatformAdmins = false
    @State private var showChapterRequests = false
    
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
                            ProfileInfoRow(icon: "shield.fill", title: String(localized: "Nível de Acesso"), value: authViewModel.accessLevel.displayName)
                            if let birthdate = profile?.birthdate {
                                ProfileInfoRow(icon: "calendar", title: "Data de Nascimento", value: birthdate.formatted(.dateTime.day().month(.twoDigits).year()))
                            }
                            ProfileInfoRow(icon: "star.fill", title: "Cargo", value: authViewModel.activeMembership?.role.map(ChapterRole.displayName) ?? ChapterRole.noRole)
                        } header: {
                            Text("Informações")
                        }
                        
                        if authViewModel.memberships.count > 1 {
                            Section {
                                ForEach(authViewModel.memberships) { membership in
                                    ChapterSwitchRow(
                                        membership: membership,
                                        isActive: membership.id == authViewModel.activeMembership?.id
                                    ) {
                                        Task { await authViewModel.switchChapter(to: membership) }
                                    }
                                }
                            } header: {
                                Text("Meus Capítulos")
                            } footer: {
                                Text("A dupla filiação permite dois Capítulos. O app mostra um de cada vez; toque para trocar.")
                            }
                        }

                        if let chapterId = authViewModel.currentChapterId {
                            Section {
                                ProfileNavigationRow(
                                    icon: "person.badge.clock",
                                    title: String(localized: "Solicitações de entrada"),
                                    hint: String(localized: "Abre a fila de quem pediu para entrar no Capítulo")
                                ) { showJoinRequests = true }
                                .requires(.reviewJoinRequests)

                                ProfileNavigationRow(
                                    icon: "ticket",
                                    title: "Convites",
                                    hint: String(localized: "Gera um código para alguém entrar direto no Capítulo")
                                ) { showInvites = true }
                                .requires(.manageInvites)
                            } header: {
                                Text("Administração")
                            }
                            .requires(.reviewJoinRequests)
                            .sheet(isPresented: $showJoinRequests) {
                                JoinRequestsView(chapterId: chapterId)
                            }
                            .sheet(isPresented: $showInvites) {
                                InviteManagementView(
                                    chapterId: chapterId,
                                    chapterName: authViewModel.activeChapterName
                                )
                            }
                        }

                        if authViewModel.isPlatformAdmin {
                            Section {
                                ProfileNavigationRow(
                                    icon: "checkmark.seal",
                                    title: "Fundações pendentes",
                                    hint: "Revisa quem pediu para ser o primeiro administrador de um Capítulo"
                                ) { showBootstrapQueue = true }

                                ProfileNavigationRow(
                                    icon: "person.badge.key",
                                    title: "Administradores de plataforma",
                                    hint: "Concede e revoga quem pode aprovar fundações"
                                ) { showPlatformAdmins = true }

                                ProfileNavigationRow(
                                    icon: "tray",
                                    title: "Capítulos solicitados",
                                    hint: "Revisa pedidos de Capítulo que não está no catálogo"
                                ) { showChapterRequests = true }
                            } header: {
                                Text("Plataforma")
                            }
                            .requires(.reviewChapterBootstrap)
                            .sheet(isPresented: $showBootstrapQueue) {
                                BootstrapQueueView()
                            }
                            .sheet(isPresented: $showPlatformAdmins) {
                                PlatformAdminsView()
                            }
                            .sheet(isPresented: $showChapterRequests) {
                                ChapterRequestsView()
                            }
                        }

                        Section {
                            Button(action: {
                                showLeaveChapterAlert = true
                            }) {
                                Text("Sair do Capítulo")
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
            // Sem isto, uma recusa do servidor (sair sendo o único Fundador, por
            // exemplo) morre no ViewModel e o botão parece simplesmente não funcionar.
            .toast(
                isPresented: Binding(
                    get: { authViewModel.errorMessage != nil },
                    set: { if !$0 { authViewModel.errorMessage = nil } }
                ),
                message: authViewModel.errorMessage ?? "",
                style: .error
            )
        }
    }
}

struct ChapterSwitchRow: View {
    let membership: ChapterMembership
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            guard !isActive else { return }
            HapticManager.shared.impact(style: .light)
            onSelect()
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isActive ? Theme.accent : Theme.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(membership.fullName)
                        .foregroundColor(Theme.textPrimary)

                    Text(membership.role ?? membership.accessLevel.displayName)
                        .font(Typography.footnote)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }
        }
        .disabled(isActive)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isActive ? "Capítulo aberto no momento" : "Toca duas vezes para abrir este Capítulo")
    }
}

struct ProfileNavigationRow: View {
    let icon: String
    let title: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.footnote)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .accessibilityHint(hint)
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
