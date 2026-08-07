import SwiftUI

struct RequestChapterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var viewModel = RequestChapterViewModel()
    @State private var didSubmit = false

    enum FocusField { case name, number, city, note }
    @FocusState private var focusedField: FocusField?

    var body: some View {
        NavigationStack {
            Group {
                if didSubmit {
                    RequestChapterConfirmation { dismiss() }
                } else {
                    form
                }
            }
            .navigationTitle(didSubmit ? "Solicitação enviada" : "Solicitar Capítulo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !didSubmit {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(Theme.textSecondary)
                        .accessibilityLabel("Cancelar")
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: submit) {
                            Image(systemName: "paperplane.fill")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                        .disabled(!viewModel.isValid)
                        .accessibilityLabel("Enviar solicitação")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(message: "Enviando solicitação...")
                }
            }
        }
        .alert(
            "Não foi possível enviar",
            isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: {
                if let message = viewModel.errorMessage { Text(message) }
            }
        )
    }

    private var form: some View {
        Form {
            Section {
                TextField("Nome do Capítulo", text: $viewModel.name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .number }
                    .textContentType(.organizationName)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.name) { _, newValue in
                        if newValue.count > 60 { viewModel.name = String(newValue.prefix(60)) }
                    }

                TextField("Número", text: $viewModel.number)
                    .focused($focusedField, equals: .number)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .city }
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.number) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > 5 {
                            viewModel.number = String(filtered.prefix(5))
                        } else if viewModel.number != filtered {
                            viewModel.number = filtered
                        }
                    }
            } header: {
                Text("O Capítulo")
            } footer: {
                Text("No Brasil a numeração é por jurisdição estadual, então o estado é obrigatório.")
            }

            Section {
                Picker("Estado", selection: $viewModel.uf) {
                    ForEach(BrazilianState.allCases) { state in
                        Text("\(state.name) (\(state.rawValue))").tag(state)
                    }
                }

                TextField("Cidade (opcional)", text: $viewModel.city)
                    .focused($focusedField, equals: .city)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .note }
                    .textContentType(.addressCity)
            } header: {
                Text("Onde fica")
            }

            Section {
                TextField("Alguma informação que ajude a confirmar", text: $viewModel.note, axis: .vertical)
                    .focused($focusedField, equals: .note)
                    .lineLimit(3...6)
            } header: {
                Text("Observação (opcional)")
            } footer: {
                Text("Um site, rede social ou o nome da Loja patrocinadora acelera a conferência.")
            }
        }
    }

    private func submit() {
        guard let userId = authViewModel.currentUserId else { return }
        Task {
            let sent = await viewModel.submit(requestedBy: userId)
            if sent {
                HapticManager.shared.notification(type: .success)
                withAnimation { didSubmit = true }
            } else {
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}

private struct RequestChapterConfirmation: View {
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                Image(systemName: "paperplane.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)

                VStack(spacing: Spacing.xs) {
                    Text("Recebemos sua solicitação")
                        .font(Typography.title2)
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Vamos conferir os dados com o registro da Ordem e avisar assim que o Capítulo entrar na lista. Enquanto isso, você pode continuar usando o app normalmente.")
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.screenEdgePadding)

                Spacer()

                Button("Entendi", action: onDone)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.screenEdgePadding)
            }
            .padding(.vertical, Spacing.xl)
        }
    }
}

private struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: Spacing.sm) {
                ProgressView().tint(Theme.accent)
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Spacing.lg)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
            .accessibilityLabel(message)
        }
    }
}
