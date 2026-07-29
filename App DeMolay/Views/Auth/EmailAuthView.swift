import SwiftUI

struct EmailAuthView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    enum FocusField { case email, password, confirmPassword }
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(isSignUp ? "Criar Conta" : "Bem-vindo de volta")
                            .font(Typography.largeTitle)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(isSignUp ? "Preencha seus dados para começar." : "Faça login para acessar seu Capítulo.")
                            .font(Typography.body)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("E-mail")
                                .font(Typography.callout)
                                .foregroundColor(Theme.textPrimary)
                            
                            TextField("Digite seu e-mail", text: $email)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Theme.backgroundSecondary)
                                .cornerRadius(8)
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Senha")
                                .font(Typography.callout)
                                .foregroundColor(Theme.textPrimary)
                            
                            SecureField("Digite sua senha", text: $password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(isSignUp ? .next : .done)
                                .onSubmit {
                                    if isSignUp {
                                        focusedField = .confirmPassword
                                    } else {
                                        focusedField = nil
                                    }
                                }
                                .padding()
                                .background(Theme.backgroundSecondary)
                                .cornerRadius(8)
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Confirmar Senha")
                                    .font(Typography.callout)
                                    .foregroundColor(Theme.textPrimary)
                                
                                SecureField("Confirme sua senha", text: $confirmPassword)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .submitLabel(.done)
                                    .onSubmit { focusedField = nil }
                                    .padding()
                                    .background(Theme.backgroundSecondary)
                                    .cornerRadius(8)
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(Typography.caption1)
                            .foregroundColor(Theme.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: Spacing.md) {
                        Button(action: {
                            Task {
                                isLoading = true
                                authViewModel.errorMessage = nil
                                if isSignUp {
                                    if password == confirmPassword {
                                        await authViewModel.signUpWithEmail(email: email, password: password)
                                    } else {
                                        authViewModel.errorMessage = "As senhas não coincidem."
                                    }
                                } else {
                                    await authViewModel.signInWithEmail(email: email, password: password)
                                }
                                isLoading = false
                            }
                        }) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Cadastrar" : "Entrar")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty || password.isEmpty || (isSignUp && confirmPassword.isEmpty) || isLoading)
                        
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                authViewModel.errorMessage = nil
                            }
                        }) {
                            Text(isSignUp ? "Já tem uma conta? Entre aqui." : "Não tem conta? Cadastre-se.")
                                .font(Typography.callout)
                                .foregroundColor(Theme.accent)
                        }
                    }
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
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        EmailAuthView()
            .environment(AuthViewModel(authService: AuthService()))
    }
}
