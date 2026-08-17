import SwiftUI

/// A fila de quem pediu um Capítulo que não está no catálogo.
///
/// Aprovar insere no registro, que é somente leitura para o app — só a RPC escreve
/// ali. A tela não decide isso; ela só não desenha o que o servidor recusaria.
struct ChapterRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ChapterRequestsViewModel()
    @State private var requestToReject: PendingChapterRequest?
    @State private var requestToApprove: PendingChapterRequest?
    @State private var rejectReason = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.requests.isEmpty && !viewModel.isLoading {
                    EmptyStateCard(cardType: .chapterRequests)
                } else {
                    list
                }
            }
            .navigationTitle("Capítulos solicitados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.requests) { request in
                Section {
                    ChapterRequestCard(request: request)

                    // `chapter` é registro somente-leitura para o app: o que entra aqui não
                    // pode ser corrigido nem apagado depois, só por migration. Um toque
                    // acidental gravava um Capítulo no catálogo público com nome ou número
                    // errado — enquanto recusar, que é reversível, já pedia confirmação.
                    Button("Aprovar e cadastrar") {
                        requestToApprove = request
                    }
                    .disabled(viewModel.isLoading)

                    Button("Recusar", role: .destructive) {
                        rejectReason = ""
                        requestToReject = request
                    }
                    .disabled(viewModel.isLoading)
                }
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
        .alert("Recusar esta solicitação?", isPresented: Binding(
            get: { requestToReject != nil },
            set: { if !$0 { requestToReject = nil } }
        )) {
            TextField("Motivo (opcional)", text: $rejectReason)
            Button("Recusar", role: .destructive) {
                if let request = requestToReject {
                    let reason = rejectReason
                    Task {
                        _ = await viewModel.reject(request, reason: reason.isEmpty ? nil : reason)
                        requestToReject = nil
                    }
                }
            }
            Button("Cancelar", role: .cancel) { requestToReject = nil }
        } message: {
            Text("Quem pediu recebe uma notificação. O motivo ajuda a pessoa a entender o que corrigir.")
        }
        .confirmationDialog(
            Text("Cadastrar este Capítulo no catálogo?"),
            isPresented: Binding(
                get: { requestToApprove != nil },
                set: { if !$0 { requestToApprove = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Aprovar e cadastrar") {
                if let request = requestToApprove {
                    Task {
                        _ = await viewModel.approve(request)
                        requestToApprove = nil
                    }
                }
            }
            Button("Cancelar", role: .cancel) { requestToApprove = nil }
        } message: {
            if let request = requestToApprove {
                Text("\(request.name), nº \(request.number) · \(request.uf). O registro não pode ser corrigido pelo app depois — confira o número e a jurisdição.")
            }
        }
    }
}

private struct ChapterRequestCard: View {
    let request: PendingChapterRequest

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("\(request.name) nº \(request.number)")
                .font(Typography.headline)

            Text(request.location)
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)

            if let note = request.note, !note.isEmpty {
                Text(note)
                    .font(Typography.caption1)
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xxs)
            }

            Text("Pedido por \(request.requesterName)")
                .font(Typography.caption2)
                .foregroundColor(Theme.textTertiary)
                .padding(.top, Spacing.xxs)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
    }
}
