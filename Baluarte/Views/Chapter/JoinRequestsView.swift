import SwiftUI

struct JoinRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: JoinRequestsViewModel
    @State private var reviewing: PendingJoinRequest?

    init(chapterId: UUID) {
        _viewModel = State(initialValue: JoinRequestsViewModel(chapterId: chapterId))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(Theme.accent)
                } else if viewModel.requests.isEmpty {
                    EmptyQueueState()
                        .padding(Spacing.screenEdgePadding)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(viewModel.requests) { pending in
                                JoinRequestRow(pending: pending) {
                                    viewModel.resetForm(for: pending)
                                    reviewing = pending
                                }
                            }
                        }
                        .padding(Spacing.screenEdgePadding)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Solicitações")
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
            .sheet(item: $reviewing) { pending in
                ReviewJoinRequestSheet(pending: pending, viewModel: viewModel)
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

private struct EmptyQueueState: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .resizable()
                .scaledToFit()
                .frame(height: Spacing.heroIconSize)
                .foregroundColor(Theme.accent)
                .accessibilityHidden(true)

            Text("Nenhuma solicitação pendente")
                .font(Typography.headline)
                .foregroundColor(Theme.textPrimary)

            Text("Quando alguém pedir para entrar no Capítulo, a solicitação aparece aqui para você aprovar ou recusar.")
                .font(Typography.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct JoinRequestRow: View {
    let pending: PendingJoinRequest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(pending.applicantName)
                        .font(Typography.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text(subtitle)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    if let message = pending.request.message, !message.isEmpty {
                        Text(message)
                            .font(Typography.footnote)
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(2)
                    }
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
        .accessibilityHint("Toca duas vezes para revisar esta solicitação")
    }

    private var subtitle: String {
        var parts: [String] = []
        if let cid = pending.request.cidSnapshot, !cid.isEmpty { parts.append("CID \(cid)") }
        parts.append(pending.request.createdAt.formatted(.dateTime.day().month(.abbreviated)))
        return parts.joined(separator: " · ")
    }
}

private struct ReviewJoinRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    let pending: PendingJoinRequest
    @Bindable var viewModel: JoinRequestsViewModel

    @State private var rejectReason = ""
    @State private var showRejectFields = false
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Nome", value: pending.applicantName)
                    if let cid = pending.request.cidSnapshot, !cid.isEmpty {
                        LabeledContent("CID", value: cid)
                    }
                    LabeledContent(
                        "Solicitado em",
                        value: pending.request.createdAt.formatted(.dateTime.day().month(.wide).hour().minute())
                    )
                    if let message = pending.request.message, !message.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Recado").font(Typography.footnote).foregroundColor(Theme.textSecondary)
                            Text(message).font(Typography.body).foregroundColor(Theme.textPrimary)
                        }
                    }
                } header: {
                    Text("Quem está pedindo")
                }

                Section {
                    Picker("Categoria", selection: $viewModel.category) {
                        ForEach(MembershipCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }

                    Picker("Cargo", selection: $viewModel.role) {
                        ForEach(JoinRequestsViewModel.memberRoles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    .onChange(of: viewModel.role) { _, _ in
                        viewModel.applyRoleSuggestion()
                    }

                    Picker("Nível de acesso", selection: $viewModel.accessLevel) {
                        Text(AccessLevel.member.displayName).tag(AccessLevel.member)
                        Text(AccessLevel.admin.displayName).tag(AccessLevel.admin)
                    }
                } header: {
                    Text("Como vai entrar")
                } footer: {
                    if viewModel.suggestsAdmin {
                        Text("Sugerido pelo cargo. O cargo muda a cada gestão — a permissão não muda sozinha junto, então confirme se é isso mesmo que você quer.")
                    } else {
                        Text("Cargo é descritivo. Quem administra o Capítulo no app é definido aqui, separadamente.")
                    }
                }

                if !viewModel.unclaimedEntries.isEmpty {
                    Section {
                        Picker("Cadastro", selection: $viewModel.linkedMembershipId) {
                            Text("Criar um novo").tag(UUID?.none)
                            ForEach(viewModel.unclaimedEntries) { entry in
                                Text(entry.fullName).tag(UUID?.some(entry.id))
                            }
                        }
                    } header: {
                        Text("Já existe na lista?")
                    } footer: {
                        Text("Se alguém já tinha cadastrado esta pessoa à mão, escolher o cadastro existente evita duplicar e preserva presenças, tarefas e comissões dela.")
                    }
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
                        act { await viewModel.approve(pending) }
                    } label: {
                        Text("Aprovar entrada")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    Button {
                        if showRejectFields {
                            act { await viewModel.reject(pending, reason: rejectReason) }
                        } else {
                            withAnimation { showRejectFields = true }
                        }
                    } label: {
                        Text(showRejectFields ? "Confirmar recusa" : "Recusar")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .disabled(isWorking)
            .navigationTitle("Revisar solicitação")
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
