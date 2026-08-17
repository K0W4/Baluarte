import SwiftUI

/// O que aconteceu com a autoridade do Capítulo, em ordem inversa. A tela não filtra
/// nem esconde nada: quem chega aqui já passou pela restrição do servidor, e uma
/// auditoria com parte omitida não serve para responder à pergunta que a motivou.
struct AccessLogView: View {
    let scope: AccessLogScope

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AccessLogViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Histórico de acesso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = AccessLogViewModel(scope: scope)
                await viewModel?.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: AccessLogViewModel) -> some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.destructive)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if viewModel.isEmpty && viewModel.errorMessage == nil {
                Section {
                    Text("Nada registrado ainda. Promoções, rebaixamentos, transferências de posse e convites retirados aparecem aqui.")
                        .font(Typography.callout)
                        .foregroundColor(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section {
                ForEach(viewModel.rows) { row in
                    AccessLogEntryRow(row: row)
                }

                if viewModel.hasMore {
                    Button("Carregar mais") {
                        Task { await viewModel.loadMore() }
                    }
                    .disabled(viewModel.isLoading)
                    .frame(minHeight: Spacing.minTouchTarget)
                }
            } footer: {
                if !viewModel.isEmpty {
                    Text("O registro não pode ser editado nem apagado pelo app.")
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                ProgressView()
            }
        }
    }
}

struct AccessLogEntryRow: View {
    let row: AccessLogRow

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(headline)
                .font(Typography.body)
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(attribution)
                .font(Typography.caption1)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xxs)
        .frame(minHeight: Spacing.minTouchTarget, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(headline). \(attribution)")
    }

    private var subjectName: String {
        Self.name(of: row.subject)
    }

    private var headline: String {
        switch row.event {
        case let .joinedWith(level):
            let format = String(localized: "%1$@ entrou como %2$@")
            return String(format: format, subjectName, level.displayName.lowercased())
        case let .promoted(level):
            let format = String(localized: "%1$@ passou a %2$@")
            return String(format: format, subjectName, level.displayName.lowercased())
        case let .demoted(level):
            let format = String(localized: "%1$@ voltou a %2$@")
            return String(format: format, subjectName, level.displayName.lowercased())
        case .ownershipTransferred:
            let format = String(localized: "%@ recebeu a posse do Capítulo")
            return String(format: format, subjectName)
        case .accessClearedOnAccountDeletion:
            let format = String(localized: "%@ excluiu a conta e perdeu o acesso")
            return String(format: format, subjectName)
        case .platformAdminGranted:
            let format = String(localized: "%@ passou a administrar a plataforma")
            return String(format: format, subjectName)
        case .platformAdminRevoked:
            let format = String(localized: "%@ deixou de administrar a plataforma")
            return String(format: format, subjectName)
        case .inviteRevoked:
            return String(localized: "Um convite foi revogado")
        case .inviteDeleted:
            return String(localized: "Um convite foi excluído")
        case .unknown:
            return String(localized: "Mudança de acesso registrada")
        }
    }

    private var attribution: String {
        let moment = row.occurredAt.formatted(.dateTime.day().month().year().hour().minute())

        switch row.actor {
        case let .person(name):
            let format = String(localized: "por %1$@ · %2$@")
            return String(format: format, name, moment)
        case .removedAccount:
            let format = String(localized: "por uma conta removida · %@")
            return String(format: format, moment)
        case .system:
            let format = String(localized: "pelo sistema · %@")
            return String(format: format, moment)
        }
    }

    private static func name(of party: AccessLogParty?) -> String {
        switch party {
        case let .person(name): return name
        case .removedAccount, .none: return String(localized: "Conta removida")
        case .system: return String(localized: "Sistema")
        }
    }
}
