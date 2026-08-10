import SwiftUI

struct BootstrapQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BootstrapQueueViewModel()
    @State private var reviewing: BootstrapRequest?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(Theme.accent)
                } else if viewModel.requests.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "checkmark.seal")
                            .resizable()
                            .scaledToFit()
                            .frame(height: Spacing.heroIconSize)
                            .foregroundColor(Theme.accent)
                            .accessibilityHidden(true)

                        Text("Nenhuma fundação pendente")
                            .font(Typography.headline)
                            .foregroundColor(Theme.textPrimary)

                        Text("Quando alguém pedir para ser o primeiro administrador de um Capítulo, a solicitação aparece aqui com o comprovante.")
                            .font(Typography.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.screenEdgePadding)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(viewModel.requests) { request in
                                BootstrapRow(request: request) { reviewing = request }
                            }
                        }
                        .padding(Spacing.screenEdgePadding)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Fundações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .accessibilityLabel("Fechar")
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(item: $reviewing) { request in
                ReviewBootstrapSheet(request: request, viewModel: viewModel)
            }
            .toast(
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                message: viewModel.errorMessage ?? "",
                style: .error
            )
        }
    }
}

private struct BootstrapRow: View {
    let request: BootstrapRequest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(request.chapterLabel)
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text(request.applicantName)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    Text(request.createdAt.formatted(.dateTime.day().month(.abbreviated).hour().minute()))
                        .font(Typography.footnote)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer(minLength: Spacing.xs)

                Image(systemName: "chevron.right")
                    .font(Typography.body)
                    .foregroundColor(Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Toca duas vezes para revisar o comprovante")
    }
}

private struct ReviewBootstrapSheet: View {
    @Environment(\.dismiss) private var dismiss
    let request: BootstrapRequest
    let viewModel: BootstrapQueueViewModel

    @State private var proofURL: URL?
    @State private var rejectReason = ""
    @State private var showRejectFields = false
    @State private var showApproveConfirmation = false
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Capítulo", value: request.chapterLabel)
                    LabeledContent("Quem pediu", value: request.applicantName)
                    if let cid = request.cidSnapshot, !cid.isEmpty {
                        LabeledContent("CID", value: cid)
                    }
                    LabeledContent(
                        "Enviado em",
                        value: request.createdAt.formatted(.dateTime.day().month(.wide).hour().minute())
                    )
                }

                if let message = request.message, !message.isEmpty {
                    Section {
                        Text(message)
                            .font(Typography.body)
                            .foregroundColor(Theme.textPrimary)
                    } header: {
                        Text("O que informou")
                    }
                }

                Section {
                    if let proofURL {
                        AsyncImage(url: proofURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                            case .failure:
                                Text("Não foi possível carregar o comprovante.")
                                    .font(Typography.footnote)
                                    .foregroundColor(Theme.textSecondary)
                            default:
                                ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
                    } else {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                    }
                } header: {
                    Text("Comprovante")
                } footer: {
                    Text("O link expira em poucos minutos — o arquivo nunca fica público.")
                }

                if showRejectFields {
                    Section {
                        TextField("Motivo (opcional)", text: $rejectReason, axis: .vertical)
                            .lineLimit(2...4)
                    } header: {
                        Text("Recusar")
                    }
                }

                Section {
                    Button {
                        // Um toque entregava a autoridade máxima de um Capítulo, sem volta:
                        // só o novo Fundador pode transferir a posse de novo. Revogar um
                        // convite, infinitamente menor, já pedia confirmação.
                        showApproveConfirmation = true
                    } label: {
                        Text("Aprovar como Fundador")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .confirmationDialog(
                        Text("Tornar \(request.applicantName) Fundador do Capítulo?"),
                        isPresented: $showApproveConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Aprovar como Fundador", role: .destructive) {
                            act { await viewModel.approve(request) }
                        }
                        Button("Cancelar", role: .cancel) { }
                    } message: {
                        Text("Só o novo Fundador poderá transferir a posse depois. Confira o comprovante antes de aprovar.")
                    }

                    Button {
                        if showRejectFields {
                            act { await viewModel.reject(request, reason: rejectReason) }
                        } else {
                            withAnimation { showRejectFields = true }
                        }
                    } label: {
                        Text(showRejectFields ? "Confirmar recusa" : "Recusar")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text("Aprovar dá a esta pessoa a posse do Capítulo: ela passa a aprovar entradas e gerar convites.")
                }
            }
            .disabled(isWorking)
            .navigationTitle("Revisar fundação")
            // Idem: e aqui é pior, porque a falha da URL assinada do comprovante deixava
            // um spinner girando para sempre com a mensagem presa atrás da folha.
            .toast(
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                message: viewModel.errorMessage ?? "",
                style: .error
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .accessibilityLabel("Fechar")
                }
            }
            .task { proofURL = await viewModel.proofURL(for: request) }
        }
    }

    private func act(_ operation: @escaping () async -> Bool) {
        Task {
            isWorking = true
            let ok = await operation()
            isWorking = false
            if ok {
                HapticManager.shared.notification(type: .success)
                dismiss()
            } else {
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}
