import SwiftUI

/// Fim do caminho de recuperação de senha. Chega aqui quem abriu o link do e-mail:
/// o `AuthService` já trocou o token por uma sessão, então só falta a senha nova.
///
/// É apresentada como sheet sobre qualquer rota de propósito — o link pode ser aberto
/// por quem está deslogado, dentro do app, ou parado na fila de aprovação.
struct SetNewPasswordView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSaving = false
    @FocusState private var focused: Field?

    private enum Field { case password, confirmation }

    private static let minLength = PasswordPolicy.minLength

    private var validationMessage: String? {
        if password.isEmpty { return nil }
        if password.count < Self.minLength {
            return String(format: String(localized: "A senha precisa ter ao menos %lld caracteres."), Self.minLength)
        }
        if !confirmation.isEmpty && password != confirmation {
            return String(localized: "As senhas não coincidem.")
        }
        return nil
    }

    private var canSave: Bool {
        password.count >= Self.minLength && password == confirmation && !isSaving
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Escolha uma senha nova para entrar no Baluarte.")
                    .font(Typography.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: Spacing.sm) {
                    SecureField("Nova senha", text: $password)
                        .textContentType(.newPassword)
                        .focused($focused, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focused = .confirmation }

                    SecureField("Repita a senha", text: $confirmation)
                        .textContentType(.newPassword)
                        .focused($focused, equals: .confirmation)
                        .submitLabel(.done)
                        .onSubmit { if canSave { save() } }
                }
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: Spacing.minTouchTarget)

                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.circle")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.destructive)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let errorMessage = authViewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.destructive)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: save) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Salvar senha")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSave)

                Spacer()
            }
            .padding(Spacing.screenEdgePadding)
            .navigationTitle("Nova senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Agora não") { authViewModel.isSettingNewPassword = false }
                }
            }
            .onAppear { focused = .password }
        }
    }

    private func save() {
        isSaving = true
        Task {
            let saved = await authViewModel.setNewPassword(password)
            isSaving = false
            if saved { HapticManager.shared.notification(type: .success) }
        }
    }
}
