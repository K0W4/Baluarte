import SwiftUI

struct CompleteProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var fullName: String = ""
    @State private var cid: String = ""
    @State private var birthDate: Date = Date()
    @State private var isActive: Bool = true
    @State private var isSenior: Bool = false
    @State private var isMason: Bool = false
    @State private var isLoading = false
    
    enum FocusField { case fullName, cid }
    @FocusState private var focusedField: FocusField?
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Quase lá!")
                            .font(Typography.largeTitle)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Precisamos de mais alguns dados para finalizar seu cadastro.")
                            .font(Typography.body)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Nome Completo")
                                    .font(Typography.callout)
                                    .foregroundColor(Theme.textPrimary)
                                
                                TextField("Digite seu nome completo", text: $fullName)
                                    .focused($focusedField, equals: .fullName)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .cid }
                                    .textContentType(.name)
                                    .padding()
                                    .background(Theme.backgroundSecondary)
                                    .cornerRadius(8)
                                    .foregroundColor(Theme.textPrimary)
                            }
                            
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("ID (Identidade DeMolay)")
                                .font(Typography.callout)
                                .foregroundColor(Theme.textPrimary)
                            
                            TextField("Digite seu ID", text: $cid)
                                .focused($focusedField, equals: .cid)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Theme.backgroundSecondary)
                                .cornerRadius(8)
                                .foregroundColor(Theme.textPrimary)
                                .onChange(of: cid) { oldValue, newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 7 {
                                        cid = String(filtered.prefix(7))
                                    } else if cid != filtered {
                                        cid = filtered
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Data de Nascimento")
                                .font(Typography.callout)
                                .foregroundColor(Theme.textPrimary)
                            
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                            
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Seu Status (Selecione os que se aplicam)")
                                    .font(Typography.callout)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Toggle("Ativo", isOn: $isActive)
                                    .tint(Theme.accent)
                                    .onChange(of: isActive) { _, newValue in
                                        if newValue {
                                            isSenior = false
                                            isMason = false
                                        }
                                    }
                                
                                Toggle("Sênior", isOn: $isSenior)
                                    .tint(Theme.accent)
                                    .onChange(of: isSenior) { _, newValue in
                                        if newValue {
                                            isActive = false
                                        }
                                    }
                                
                                Toggle("Maçom", isOn: $isMason)
                                    .tint(Theme.accent)
                                    .onChange(of: isMason) { _, newValue in
                                        if newValue {
                                            isActive = false
                                        }
                                    }
                            }
                            .padding()
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(Typography.caption1)
                            .foregroundColor(Theme.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        Task {
                            isLoading = true
                            authViewModel.errorMessage = nil
                            await authViewModel.completeProfile(
                                fullName: fullName,
                                cid: cid,
                                birthDate: birthDate,
                                isActive: isActive,
                                isSenior: isSenior,
                                isMason: isMason
                            )
                            isLoading = false
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continuar")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(fullName.isEmpty || cid.isEmpty || isLoading || (!isActive && !isSenior && !isMason))
                }
                .padding(Spacing.screenEdgePadding)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sair") {
                        showSignOutAlert = true
                    }
                    .foregroundColor(Theme.destructive)
                }
            }
            .alert("Deseja sair da conta?", isPresented: $showSignOutAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Sair", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            }
        }
    }
}
