import SwiftUI

struct CreateChapterView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var chapterName: String = ""
    @State private var chapterNumber: String = ""
    @State private var viewModel = CreateChapterViewModel()
    
    enum FocusField { case name, number }
    @FocusState private var focusedField: FocusField?
    
    var onSuccess: (() -> Void)?
    
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
                    
                    TextField("Número do Capítulo", text: $chapterNumber)
                        .focused($focusedField, equals: .number)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Criar capítulo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            guard let number = Int(chapterNumber) else {
                                viewModel.errorMessage = "Número inválido"
                                return
                            }
                            
                            do {
                                _ = try await viewModel.createChapter(name: chapterName, number: number)
                                onSuccess?()
                                dismiss()
                            } catch {
                                // Erro já tratado na ViewModel
                            }
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(chapterName.isEmpty || chapterNumber.isEmpty || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(8)
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
}

#Preview {
    CreateChapterView()
}
