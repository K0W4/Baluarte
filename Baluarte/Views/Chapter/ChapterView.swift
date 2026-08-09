import SwiftUI

/// Tudo que é do Capítulo, num lugar só.
///
/// Antes isto morava dentro de "Meu perfil", que tinha virado centro administrativo
/// por acúmulo: dados da pessoa, troca de Capítulo, fila de entrada, convites,
/// auditoria e ações de plataforma na mesma lista. Duas coisas diferentes com o mesmo
/// nome — o que uma pessoa é, e o que ela administra.
struct ChapterView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showJoinRequests = false
    @State private var showInvites = false
    @State private var showAccessLog = false
    @State private var showLeaveAlert = false

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            List {
                if let chapter = authViewModel.activeChapter {
                    ChapterIdentityHeader(chapter: chapter)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                standingSection

                if authViewModel.memberships.count > 1 {
                    chapterSwitchSection
                }

                if let chapterId = authViewModel.currentChapterId {
                    administrationSection(chapterId: chapterId)
                }

                leaveSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Capítulo")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sair do capítulo", isPresented: $showLeaveAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Sair", role: .destructive) {
                Task {
                    await authViewModel.leaveChapter()
                    dismiss()
                }
            }
        } message: {
            Text("Tem certeza que deseja sair do seu Capítulo atual? Você deixará de ver os eventos, metas e tarefas dele, mas poderá entrar em outro Capítulo quando quiser.")
        }
    }

    /// Cargo e nível de acesso são do vínculo, não da pessoa: mudam a cada gestão e
    /// mudam de novo quando alguém troca de Capítulo. Ficavam em "Meu perfil" como se
    /// fossem atributos permanentes de quem está logado.
    private var standingSection: some View {
        Section {
            ProfileInfoRow(
                icon: "star.fill",
                title: String(localized: "Cargo"),
                value: authViewModel.activeMembership?.role.map(ChapterRole.displayName) ?? ChapterRole.noRole
            )
            ProfileInfoRow(
                icon: "shield.fill",
                title: String(localized: "Nível de Acesso"),
                value: authViewModel.accessLevel.displayName
            )
        } header: {
            Text("Minha posição")
        } footer: {
            Text("O cargo é descritivo e muda a cada gestão. O nível de acesso é o que decide o que você pode administrar, e não muda junto.")
        }
    }

    private var chapterSwitchSection: some View {
        Section {
            ForEach(authViewModel.memberships) { membership in
                ChapterSwitchRow(
                    membership: membership,
                    chapterName: authViewModel.chapterName(for: membership),
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

    private func administrationSection(chapterId: UUID) -> some View {
        Section {
            ProfileNavigationRow(
                icon: "person.badge.clock",
                title: String(localized: "Solicitações de entrada"),
                hint: String(localized: "Abre a fila de quem pediu para entrar no Capítulo")
            ) { showJoinRequests = true }
            .requires(.reviewJoinRequests)

            ProfileNavigationRow(
                icon: "ticket",
                title: String(localized: "Convites"),
                hint: String(localized: "Gera um código para alguém entrar direto no Capítulo")
            ) { showInvites = true }
            .requires(.manageInvites)

            ProfileNavigationRow(
                icon: "clock.arrow.circlepath",
                title: String(localized: "Histórico de acesso"),
                hint: String(localized: "Mostra quem promoveu, rebaixou ou transferiu a posse, e quando")
            ) { showAccessLog = true }
            .requires(.viewAccessLog)
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
        .sheet(isPresented: $showAccessLog) {
            AccessLogView(scope: .chapter(chapterId))
        }
    }

    private var leaveSection: some View {
        Section {
            Button(role: .destructive) {
                showLeaveAlert = true
            } label: {
                Text("Sair do Capítulo")
            }
            .frame(minHeight: Spacing.minTouchTarget)
        } footer: {
            Text("Sair não apaga o que você registrou aqui: presenças, tarefas e comissões continuam com o Capítulo.")
        }
    }
}

/// Qual Capítulo é este. O app nunca dizia — o nome só aparecia na saudação da tela
/// inicial, e número e jurisdição, em lugar nenhum.
struct ChapterIdentityHeader: View {
    let chapter: Chapter

    private var subtitle: String {
        let jurisdiction = [chapter.city, chapter.uf].compactMap { $0 }.joined(separator: " · ")
        let numbered = String(format: String(localized: "Capítulo nº %lld"), chapter.number)
        return jurisdiction.isEmpty ? numbered : "\(numbered) · \(jurisdiction)"
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "building.columns.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundColor(Theme.accent)
                .padding(.bottom, Spacing.xxs)

            Text(chapter.name)
                .font(Typography.title2)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(Typography.callout)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
    }
}
