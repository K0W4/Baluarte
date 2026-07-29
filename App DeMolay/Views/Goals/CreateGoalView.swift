import SwiftUI

public struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateGoalViewModel
    
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
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Informações Básicas")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(Typography.caption1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Nova meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(Theme.accent)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            let success = await viewModel.saveGoal()
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.body.bold())
                            .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                        ProgressView()
                            .tint(Theme.accent)
                    }
                }
            }
        }
    }
}

#Preview {
    CreateGoalView(chapterId: UUID())
}
