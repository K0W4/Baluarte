import SwiftUI

/// Cadeia de confiança: só quem já é administrador de plataforma concede a outro.
/// A tela não decide isso — quem decide é `set_platform_admin`, no servidor. Aqui só
/// não desenhamos o que ela recusaria.
struct PlatformAdminsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PlatformAdminsViewModel?
    @State private var adminToRevoke: PlatformAdmin?
    @State private var showGrantConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Administradores de plataforma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PlatformAdminsViewModel(currentUserId: authViewModel.currentUserId)
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: PlatformAdminsViewModel) -> some View {
        @Bindable var viewModel = viewModel

        List {
            Section {
                TextField("CID de quem vai receber", text: $viewModel.cidToGrant)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .frame(minHeight: Spacing.minTouchTarget)

                // Um dígito errado concedia a um desconhecido o poder de aprovar a fundação
                // de qualquer Capítulo da plataforma, e só se descobria quem tinha
                // recebido depois, quando a lista recarregava. Revogar, logo abaixo, já
                // confirmava com o nome da pessoa.
                Button("Conceder acesso") {
                    showGrantConfirmation = true
                }
                .disabled(!viewModel.isValidCID || viewModel.isLoading)
                .confirmationDialog(
                    Text("Conceder administração de plataforma?"),
                    isPresented: $showGrantConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Conceder acesso", role: .destructive) {
                        Task { _ = await viewModel.grant() }
                    }
                    Button("Cancelar", role: .cancel) { }
                } message: {
                    Text("O CID \(viewModel.cidToGrant) passa a aprovar a fundação de qualquer Capítulo. Confira o número com a pessoa antes de conceder.")
                }
            } header: {
                Text("Conceder")
            } footer: {
                Text("Administrador de plataforma aprova a fundação de qualquer Capítulo. Conceda só a quem você conhece, e peça o CID diretamente à pessoa.")
            }

            Section {
                if viewModel.admins.isEmpty && !viewModel.isLoading {
                    Text("Nenhum administrador de plataforma.")
                        .foregroundColor(Theme.textSecondary)
                }

                ForEach(viewModel.admins) { admin in
                    PlatformAdminRow(admin: admin, isSelf: viewModel.isSelf(admin)) {
                        adminToRevoke = admin
                    }
                }
            } header: {
                Text("Quem tem acesso")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.destructive)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .alert("Revogar acesso de plataforma?", isPresented: Binding(
            get: { adminToRevoke != nil },
            set: { if !$0 { adminToRevoke = nil } }
        ), presenting: adminToRevoke) { admin in
            Button("Revogar", role: .destructive) {
                Task {
                    _ = await viewModel.revoke(admin)
                    adminToRevoke = nil
                }
            }
            Button("Cancelar", role: .cancel) { adminToRevoke = nil }
        } message: { admin in
            Text("\(admin.fullName) deixa de aprovar fundações de Capítulo. O acesso ao próprio Capítulo não muda.")
        }
    }
}

private struct PlatformAdminRow: View {
    let admin: PlatformAdmin
    let isSelf: Bool
    let onRevoke: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(admin.fullName)
                    .font(Typography.body)
                if let email = admin.email {
                    Text(email)
                        .font(Typography.caption1)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            if isSelf {
                Text("Você")
                    .font(Typography.caption1)
                    .foregroundColor(Theme.textSecondary)
            } else {
                Button("Revogar", action: onRevoke)
                    .foregroundColor(Theme.destructive)
                    .buttonStyle(.borderless)
            }
        }
        .frame(minHeight: Spacing.minTouchTarget)
        // `.contain`, não `.combine`: fundir os filhos num elemento só absorvia o botão de
        // revogar, e a única operação destrutiva da tela ficava indisponível ao VoiceOver.
        .accessibilityElement(children: .contain)
    }
}
