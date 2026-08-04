import SwiftUI

struct CreateChapterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var chapterName: String = ""
    @State private var chapterNumber: String = ""
    @State private var viewModel = CreateChapterViewModel()

    enum FocusField { case name, number }
    @FocusState private var focusedField: FocusField?

    var onSuccess: (() -> Void)?

    private var trimmedName: String {
        chapterName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && Int(chapterNumber) != nil && !viewModel.isLoading
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informações do Capítulo")) {
                    TextField("Nome do Capítulo", text: $chapterName)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .number }
                        .textContentType(.organizationName)
                        .autocorrectionDisabled()
                        .onChange(of: chapterName) { _, newValue in
                            if newValue.count > 60 {
                                chapterName = String(newValue.prefix(60))
                            }
                        }

                    TextField("Número do Capítulo", text: $chapterNumber)
                        .focused($focusedField, equals: .number)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .keyboardType(.numberPad)
                        .onChange(of: chapterNumber) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered.count > 5 {
                                chapterNumber = String(filtered.prefix(5))
                            } else if chapterNumber != filtered {
                                chapterNumber = filtered
                            }
                        }
                }
            }
            .navigationTitle("Criar capítulo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityLabel("Cancelar")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: save) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(!isValid)
                    .accessibilityLabel("Criar capítulo")
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(8)
                        .accessibilityLabel("Criando capítulo")
                }
            }
        }
        .alert(
            "Erro ao criar capítulo",
            isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                if let errorMsg = viewModel.errorMessage {
                    Text(errorMsg)
                }
            }
        )
    }

    private func save() {
        guard let number = Int(chapterNumber) else {
            viewModel.errorMessage = "Informe o número do Capítulo usando apenas dígitos."
            return
        }

        Task {
            do {
                _ = try await viewModel.createChapter(name: trimmedName, number: number)
                HapticManager.shared.notification(type: .success)
                onSuccess?()
                dismiss()
            } catch {
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}

#Preview {
    CreateChapterView()
}
