import SwiftUI
import PhotosUI

struct BootstrapRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var viewModel: BootstrapRequestViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var didSubmit = false

    private let chapter: Chapter

    init(chapter: Chapter) {
        self.chapter = chapter
        _viewModel = State(initialValue: BootstrapRequestViewModel(chapter: chapter))
    }

    var body: some View {
        NavigationStack {
            Group {
                if didSubmit {
                    SubmittedState(
                        supportURL: viewModel.supportURL(requestReference: chapter.name),
                        onOpenSupport: { url in openURL(url) },
                        onDone: { dismiss() }
                    )
                } else {
                    form
                }
            }
            .navigationTitle(didSubmit ? "Solicitação enviada" : "Fundar o Capítulo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !didSubmit {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark").font(.body.weight(.semibold))
                        }
                        .foregroundColor(Theme.textSecondary)
                        .accessibilityLabel("Cancelar")
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: submit) {
                            if viewModel.isSending {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill").font(.body.weight(.semibold))
                            }
                        }
                        .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                        .disabled(!viewModel.isValid)
                        .accessibilityLabel("Enviar solicitação")
                    }
                }
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

    private var form: some View {
        Form {
            Section {
                Text("O **\(chapter.name) nº \(chapter.number)** ainda não tem ninguém no app. Como não há administrador para aprovar sua entrada, esta primeira solicitação é conferida por nós.")
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .listRowBackground(Color.clear)

            Section {
                TextField("Ex.: Mestre Conselheiro", text: $viewModel.role)
                    .textContentType(.jobTitle)
            } header: {
                Text("Seu cargo no Capítulo")
            } footer: {
                Text("Quem aparece na conferência costuma ser da administração da gestão atual.")
            }

            Section {
                // O rótulo do seletor é um closure @Sendable, então ele recebe um texto
                // pronto: ler o ViewModel lá dentro seria tocar um @MainActor de fora dele.
                let pickerTitle = viewModel.proofImage == nil
                    ? String(localized: "Escolher comprovante")
                    : String(localized: "Trocar comprovante")

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(pickerTitle, systemImage: "camera")
                        .foregroundColor(Theme.textPrimary)
                }
                .frame(minHeight: Spacing.minTouchTarget)

                if let proof = viewModel.proofImage {
                    ProofPreviewRow(proof: proof)
                }
            } header: {
                Text("Comprovante")
            } footer: {
                Text("Carteirinha, e-mail institucional ou print do site do Capítulo. A foto fica privada: só você e a revisão conseguem abrir.")
            }

            Section {
                TextField("Algo que ajude a confirmar", text: $viewModel.message, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Observação (opcional)")
            }
        }
        .disabled(viewModel.isSending)
        .onChange(of: photoItem) { _, newValue in
            Task {
                guard let data = try? await newValue?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                viewModel.proofImage = image
            }
        }
    }

    private func submit() {
        guard let userId = authViewModel.currentUserId else { return }
        Task {
            let sent = await viewModel.submit(memberId: userId, cid: authViewModel.currentProfile?.cid)
            if sent {
                HapticManager.shared.notification(type: .success)
                await authViewModel.refreshMembershipState()
                withAnimation { didSubmit = true }
            } else {
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}

private struct ProofPreviewRow: View {
    let proof: UIImage

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.success)
                .frame(width: 24)

            Text("Comprovante anexado")
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Image(uiImage: proof)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)
        }
    }
}

private struct SubmittedState: View {
    let supportURL: URL?
    let onOpenSupport: (URL) -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.xs) {
                    Text("Recebemos sua solicitação")
                        .font(Typography.title2)
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Vamos conferir o comprovante e avisar por aqui. Aprovado, você vira Fundador do Capítulo e passa a poder convidar o resto do pessoal.")
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.screenEdgePadding)

                Spacer()

                VStack(spacing: Spacing.sm) {
                    Button("Entendi", action: onDone)
                        .buttonStyle(PrimaryButtonStyle())

                    if let supportURL {
                        Button("Precisa de ajuda? Falar no WhatsApp") {
                            onOpenSupport(supportURL)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, Spacing.screenEdgePadding)
            }
            .padding(.vertical, Spacing.xl)
        }
    }
}
