import SwiftUI

struct EmailAuthView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var resetConfirmation: String?

    enum FocusField { case fullName, email, password, confirmPassword }
    @FocusState private var focusedField: FocusField?

    /// O mesmo piso da redefinição de senha. Eram 6 aqui e 8 lá, então quem criava a conta
    /// com 6 caracteres descobria a regra nova só ao clicar no link de recuperação.
    private static let minPasswordLength = PasswordPolicy.minLength

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailValid: Bool {
        let pattern = #"^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$"#
        return trimmedEmail.range(of: pattern, options: .regularExpression) != nil
    }

    private var emailWarning: String? {
        guard !trimmedEmail.isEmpty, !isEmailValid else { return nil }
        return String(localized: "Digite um e-mail válido, como nome@exemplo.com.")
    }

    private var passwordWarning: String? {
        guard isSignUp, !password.isEmpty, password.count < Self.minPasswordLength else { return nil }
        return String(
            format: String(localized: "A senha precisa ter ao menos %lld caracteres."),
            Self.minPasswordLength
        )
    }

    private var confirmWarning: String? {
        guard isSignUp, !confirmPassword.isEmpty, password != confirmPassword else { return nil }
        return String(localized: "As senhas não coincidem.")
    }

    private var trimmedFullName: String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        guard isEmailValid, !password.isEmpty, !isLoading else { return false }
        guard isSignUp else { return true }
        return !trimmedFullName.isEmpty
            && password.count >= Self.minPasswordLength
            && password == confirmPassword
    }

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    header
                    fields

                    if let resetConfirmation {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(Typography.headline)
                                .foregroundColor(Theme.success)

                            Text(resetConfirmation)
                                .font(Typography.subheadline)
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(3)
                        }
                        .padding(Spacing.md)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                                .stroke(Theme.success.opacity(0.5), lineWidth: 1)
                        )
                        .accessibilityElement(children: .combine)
                    }

                    if let errorMessage = authViewModel.errorMessage {
                        ErrorBannerView(
                            message: errorMessage,
                            onRetry: submit,
                            onDismiss: { authViewModel.errorMessage = nil }
                        )
                    }

                    actions
                }
                .padding(Spacing.screenEdgePadding)
            }
        }
        .navigationTitle(isSignUp ? "Cadastro" : "Login")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    authViewModel.errorMessage = nil
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Theme.accent)
                }
                .accessibilityLabel("Voltar")
            }
        }
        .navigationBarBackButtonHidden()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(isSignUp ? "Criar conta" : "Bem-vindo de volta")
                .font(Typography.largeTitle)
                .foregroundColor(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(isSignUp ? "Preencha seus dados para começar." : "Faça login para acessar seu Capítulo.")
                .font(Typography.body)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fields: some View {
        VStack(spacing: Spacing.lg) {
            if isSignUp {
                // Sem este campo o cadastro por e-mail criava o perfil com o nome de
                // reserva "Membro DeMolay", e a pessoa chegava assim na lista de membros e
                // no pedido de entrada que o administrador vai julgar. Só o caminho da
                // Apple entregava um nome de verdade.
                FormFieldContainer(title: "Nome Completo", warning: nil) {
                    TextField("Digite seu nome completo", text: $fullName)
                        .focused($focusedField, equals: .fullName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                }
            }

            FormFieldContainer(title: "E-mail", warning: emailWarning) {
                TextField("Digite seu e-mail", text: $email)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            FormFieldContainer(title: "Senha", warning: passwordWarning) {
                SecureField("Digite sua senha", text: $password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(isSignUp ? .next : .done)
                    .onSubmit { focusedField = isSignUp ? .confirmPassword : nil }
                    .textContentType(isSignUp ? .newPassword : .password)
            }

            if isSignUp {
                FormFieldContainer(title: "Confirmar Senha", warning: confirmWarning) {
                    SecureField("Confirme sua senha", text: $confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .textContentType(.newPassword)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.md) {
            Button(action: submit) {
                if isLoading {
                    ProgressView().tint(Theme.onAccent)
                } else {
                    Text(isSignUp ? "Cadastrar" : "Entrar")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSubmit)

            if !isSignUp {
                Button(action: sendReset) {
                    Text("Esqueci minha senha")
                        .font(Typography.callout)
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
                        .contentShape(Rectangle())
                }
                .disabled(!isEmailValid || isLoading)
                .accessibilityHint("Envia um link de redefinição para o e-mail informado")
            }

            Button(action: {
                withAnimation {
                    isSignUp.toggle()
                    authViewModel.errorMessage = nil
                    resetConfirmation = nil
                }
            }) {
                Text(isSignUp ? "Já tem uma conta? Entre aqui." : "Não tem conta? Cadastre-se.")
                    .font(Typography.callout)
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
                    .contentShape(Rectangle())
            }
        }
    }

    private func submit() {
        HapticManager.shared.impact(style: .medium)
        Task {
            isLoading = true
            authViewModel.errorMessage = nil
            resetConfirmation = nil
            if isSignUp {
                await authViewModel.signUpWithEmail(
                    email: trimmedEmail,
                    password: password,
                    fullName: trimmedFullName
                )
            } else {
                await authViewModel.signInWithEmail(email: trimmedEmail, password: password)
            }
            isLoading = false
            HapticManager.shared.notification(type: authViewModel.errorMessage == nil ? .success : .error)
        }
    }

    private func sendReset() {
        HapticManager.shared.impact(style: .medium)
        Task {
            isLoading = true
            authViewModel.errorMessage = nil
            resetConfirmation = nil
            let sent = await authViewModel.sendPasswordReset(to: trimmedEmail)
            if sent {
                resetConfirmation = String(localized: "Se houver uma conta com esse e-mail, enviamos um link para redefinir a senha.")
            }
            isLoading = false
            HapticManager.shared.notification(type: sent ? .success : .error)
        }
    }
}

private struct FormFieldContainer<Content: View>: View {
    let title: String
    let warning: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Typography.callout)
                .foregroundColor(Theme.textPrimary)

            content
                .padding()
                .background(Theme.backgroundSecondary)
                .cornerRadius(Spacing.cornerRadius)
                .foregroundColor(Theme.textPrimary)

            if let warning {
                Text(warning)
                    .font(Typography.caption1)
                    .foregroundColor(Theme.destructive)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}
