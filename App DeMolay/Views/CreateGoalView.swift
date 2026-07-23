import SwiftUI

public struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateGoalViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título da Meta", text: $viewModel.title)
                    
                    TextField("Valor Alvo (ex: 50.0)", text: $viewModel.targetValue)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Informações Básicas")
                }
                
                Section {
                    TextField("Descrição (Opcional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                        
                    DatePicker("Data Limite", selection: $viewModel.targetDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Detalhes e Prazo")
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
            .navigationTitle("Nova Meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        Task {
                            let success = await viewModel.saveGoal()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .font(.body.bold())
                    .foregroundColor(viewModel.isValid ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .padding()
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

#Preview {
    CreateGoalView()
}
