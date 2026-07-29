import SwiftUI
import Auth

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
    let member: Member
    
    @State private var fullName: String
    @State private var cid: String
    @State private var birthdate: Date
    @State private var isLoading = false
    
    init(member: Member) {
        self.member = member
        self._fullName = State(initialValue: member.fullName)
        self._cid = State(initialValue: member.cid ?? "")
        self._birthdate = State(initialValue: member.birthdate ?? Date())
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
                    
                    DatePicker("Data de nascimento", selection: $birthdate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Informações Pessoais")
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
                            .foregroundColor(Theme.accent)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            isLoading = true
                            let success = await authViewModel.updateProfile(fullName: fullName, cid: cid, birthdate: birthdate)
                            isLoading = false
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.body.bold())
                                .foregroundColor(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.textSecondary.opacity(0.5) : Theme.accent)
                        }
                    }
                    .disabled(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }
}
