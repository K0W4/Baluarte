import SwiftUI

/// O que atravessa Capítulos. Não é do Capítulo — aprovar uma fundação vale para
/// qualquer um — e não é bem da pessoa, é do que ela pode na plataforma. Por isso sai
/// das duas telas e fica na sua.
///
/// Quem chega aqui já é `is_platform_admin`; a restrição de verdade está em cada RPC,
/// e nenhuma delas confia nesta tela.
struct PlatformView: View {
    @State private var showBootstrapQueue = false
    @State private var showPlatformAdmins = false
    @State private var showChapterRequests = false
    @State private var showAccessLog = false

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            List {
                Section {
                    ProfileNavigationRow(
                        icon: "checkmark.seal",
                        title: String(localized: "Fundações pendentes"),
                        hint: String(localized: "Revisa quem pediu para ser o primeiro administrador de um Capítulo")
                    ) { showBootstrapQueue = true }
                    .accessibilityIdentifier("platform.bootstrapQueue")

                    ProfileNavigationRow(
                        icon: "tray",
                        title: String(localized: "Capítulos solicitados"),
                        hint: String(localized: "Revisa pedidos de Capítulo que não está no catálogo")
                    ) { showChapterRequests = true }
                    .accessibilityIdentifier("platform.chapterRequests")
                } header: {
                    Text("Filas")
                }

                Section {
                    ProfileNavigationRow(
                        icon: "person.badge.key",
                        title: String(localized: "Administradores de plataforma"),
                        hint: String(localized: "Concede e revoga quem pode aprovar fundações")
                    ) { showPlatformAdmins = true }
                    .accessibilityIdentifier("platform.admins")

                    ProfileNavigationRow(
                        icon: "clock.arrow.circlepath",
                        title: String(localized: "Histórico da plataforma"),
                        hint: String(localized: "Mostra quem concedeu e quem revogou acesso de plataforma")
                    ) { showAccessLog = true }
                    .accessibilityIdentifier("platform.accessLog")
                } header: {
                    Text("Acesso")
                } footer: {
                    Text("Administrador de plataforma aprova a fundação de qualquer Capítulo. Só quem já tem o acesso concede a outro.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Plataforma")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBootstrapQueue) {
            BootstrapQueueView()
        }
        .sheet(isPresented: $showPlatformAdmins) {
            PlatformAdminsView()
        }
        .sheet(isPresented: $showChapterRequests) {
            ChapterRequestsView()
        }
        .sheet(isPresented: $showAccessLog) {
            AccessLogView(scope: .platform)
        }
    }
}
