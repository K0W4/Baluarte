import SwiftUI
import Auth

/// Sobre a pessoa, e só. Administração do Capítulo saiu para `ChapterView` e o que
/// atravessa Capítulos, para `PlatformView`: esta tela tinha virado o centro
/// administrativo do app por acúmulo, com nove destinos de três domínios diferentes na
/// mesma lista.
struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showDeleteAccountAlert = false
    @State private var showEditProfile = false

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            if case let .authenticated(user, profile) = authViewModel.state {
                List {
                    Section {
                        PersonHeader(
                            name: profile?.fullName ?? user.email ?? String(localized: "Membro DeMolay"),
                            cid: profile?.cid
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section {
                        if let birthdate = profile?.birthdate {
                            ProfileInfoRow(
                                icon: "calendar",
                                title: String(localized: "Data de Nascimento"),
                                value: birthdate.formatted(.dateTime.day().month(.twoDigits).year())
                            )
                        }
                        ProfileInfoRow(
                            icon: "envelope",
                            title: String(localized: "E-mail"),
                            value: user.email ?? String(localized: "Conta Apple")
                        )
                    } header: {
                        Text("Informações")
                    }

                    // Ser administrador de plataforma é da pessoa, não do Capítulo:
                    // vale para qualquer um deles. Por isso é a única porta que
                    // continua saindo daqui.
                    if authViewModel.isPlatformAdmin {
                        Section {
                            NavigationLink {
                                PlatformView()
                            } label: {
                                Label("Plataforma", systemImage: "globe.americas")
                            }
                            .frame(minHeight: Spacing.minTouchTarget)
                        } footer: {
                            Text("Filas de fundação e de Capítulos solicitados, e quem administra a plataforma.")
                        }
                    }

                    Section {
                        Button {
                            Task { await authViewModel.signOut() }
                        } label: {
                            Text("Sair da conta")
                                .foregroundColor(Theme.textPrimary)
                        }
                        .frame(minHeight: Spacing.minTouchTarget)

                        Button(role: .destructive) {
                            showDeleteAccountAlert = true
                        } label: {
                            Text("Excluir conta")
                        }
                        .frame(minHeight: Spacing.minTouchTarget)
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
                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Theme.accent)
                }
                .accessibilityLabel("Editar perfil")
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if case let .authenticated(_, profile) = authViewModel.state, let profile {
                EditProfileView(profile: profile)
            }
        }
        .alert("Excluir conta", isPresented: $showDeleteAccountAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                Task { await authViewModel.deleteAccount() }
            }
        } message: {
            Text("Esta ação é irreversível. Todos os seus dados serão apagados e você perderá o acesso ao app.")
        }
        // Sem isto, uma recusa do servidor morre no ViewModel e o botão parece
        // simplesmente não funcionar.
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

struct PersonHeader: View {
    let name: String
    let cid: String?

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Theme.accent)

            Text(name)
                .font(Typography.title1)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            if let cid {
                Text("ID: \(cid)")
                    .font(Typography.callout)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
    }
}

struct ChapterSwitchRow: View {
    let membership: ChapterMembership
    /// A lista mostrava o nome da pessoa nas duas linhas, que é o mesmo nos dois
    /// vínculos — um seletor de Capítulo que não dizia o nome de Capítulo nenhum.
    let chapterName: String?
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
                    Text(chapterName ?? membership.fullName)
                        .foregroundColor(Theme.textPrimary)

                    Text(membership.role.map(ChapterRole.displayName) ?? membership.accessLevel.displayName)
                        .font(Typography.footnote)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }
        }
        .frame(minHeight: Spacing.minTouchTarget)
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
        .frame(minHeight: Spacing.minTouchTarget)
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
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: Spacing.minTouchTarget)
        .accessibilityElement(children: .combine)
    }
}
