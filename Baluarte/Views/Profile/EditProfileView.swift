import SwiftUI
import Auth

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
    let profile: UserProfile

    @State private var fullName: String
    @State private var cid: String
    @State private var birthdate: Date
    /// Falso enquanto o perfil não tiver data e ninguém tiver escolhido uma. Sem isto,
    /// quem abria a tela só para corrigir o nome saía com a data de hoje gravada como
    /// aniversário, porque o `?? Date()` do inicializador virava o valor enviado.
    @State private var birthdateWasSet: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(profile: UserProfile) {
        self.profile = profile
        self._fullName = State(initialValue: profile.fullName)
        self._cid = State(initialValue: profile.cid ?? "")
        self._birthdate = State(initialValue: profile.birthdate ?? Date())
        self._birthdateWasSet = State(initialValue: profile.birthdate != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome Completo", text: $fullName)
                        .textContentType(.name)
                    
                    TextField("ID (Opcional)", text: $cid)
                        .keyboardType(.numberPad)
                        .onChange(of: cid) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered.count > 7 {
                                cid = String(filtered.prefix(7))
                            } else if cid != filtered {
                                cid = filtered
                            }
                        }
                    
                    DatePicker(
                        "Data de nascimento",
                        selection: $birthdate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .onChange(of: birthdate) { _, _ in birthdateWasSet = true }
                } header: {
                    Text("Informações Pessoais")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Typography.footnote)
                            .foregroundColor(Theme.destructive)
                    }
                }
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(Theme.accentText)
                    }
                    .accessibilityLabel("Fechar")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            isLoading = true
                            errorMessage = nil
                            let success = await authViewModel.updateProfile(
                                fullName: fullName,
                                cid: cid,
                                birthdate: birthdateWasSet ? birthdate : nil
                            )
                            isLoading = false
                            if success {
                                dismiss()
                            } else {
                                // O toast que mostraria isto vive na ProfileView, que está
                                // atrás desta folha. Sem uma superfície aqui, um 403 por
                                // coluna não concedida some sem deixar rastro na tela.
                                errorMessage = authViewModel.errorMessage
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                                .font(.body.bold())
                                .foregroundColor(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.textSecondary.opacity(0.5) : Theme.accent)
                        }
                    }
                    .accessibilityLabel("Salvar perfil")
                    .disabled(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }
}
