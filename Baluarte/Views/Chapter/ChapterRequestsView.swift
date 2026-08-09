import SwiftUI

/// A fila de quem pediu um Capítulo que não está no catálogo.
///
/// Aprovar insere no registro, que é somente leitura para o app — só a RPC escreve
/// ali. A tela não decide isso; ela só não desenha o que o servidor recusaria.
struct ChapterRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ChapterRequestsViewModel()
    @State private var requestToReject: PendingChapterRequest?
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

                    Button("Aprovar e cadastrar") {
                        Task { _ = await viewModel.approve(request) }
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
