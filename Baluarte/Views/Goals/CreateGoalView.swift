import SwiftUI

public struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateGoalViewModel
    @State private var showDiscardAlert = false
    
    private var hasUnsavedChanges: Bool {
        !viewModel.title.isEmpty || !viewModel.targetValue.isEmpty
    }
    
    enum FocusField { case title, description, targetValue }
    @FocusState private var focusedField: FocusField?
    
    public init(chapterId: UUID) {
        _viewModel = State(initialValue: CreateGoalViewModel(chapterId: chapterId))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título da Meta", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .targetValue }
                    
                    TextField("Valor Alvo (ex: 50.0)", text: $viewModel.targetValue)
                        .focused($focusedField, equals: .targetValue)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .keyboardType(.decimalPad)
                        
                    DatePicker("Data Limite", selection: $viewModel.targetDate, displayedComponents: .date)
                } header: {
                    Text("Informações Básicas")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(Theme.destructive)
                            .font(Typography.caption1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Nova meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if hasUnsavedChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(Theme.accent)
                    }
                    .accessibilityLabel("Fechar")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        Task {
                            let success = await viewModel.saveGoal()
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.body.bold())
                            .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .accessibilityLabel("Salvar meta")
                }
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
            .alert("Descartar meta?", isPresented: $showDiscardAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Descartar", role: .destructive) { dismiss() }
            } message: {
                Text("Você tem alterações não salvas. Tem certeza que deseja descartar?")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: Spacing.sm) {
                            ProgressView()
                                .tint(Theme.accent)
                            Text("Criando meta...")
                                .font(Typography.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(Spacing.lg)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
}

#Preview {
    CreateGoalView(chapterId: UUID())
}
