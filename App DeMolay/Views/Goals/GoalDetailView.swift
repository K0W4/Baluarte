import SwiftUI

public struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: GoalDetailViewModel
    @State private var showingDeleteAlert = false
    
    public init(goal: Goal) {
        self._viewModel = State(initialValue: GoalDetailViewModel(goal: goal))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome da Meta", text: $viewModel.title)
                    
                    HStack {
                        Text("Atual:")
                            .foregroundColor(Theme.textSecondary)
                        TextField("0", text: $viewModel.currentValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Alvo:")
                            .foregroundColor(Theme.textSecondary)
                        TextField("100", text: $viewModel.targetValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Data Limite", selection: $viewModel.targetDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Informações Básicas")
                }
                .disabled(viewModel.isCompleted)
                if !viewModel.isCompleted {
                    Section {
                        Button(action: {
                            Task {
                                let success = await viewModel.completeGoal()
                                if success { dismiss() }
                            }
                        }) {
                            Text("Concluir meta")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Text("Excluir meta")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
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
            .navigationTitle("Detalhes da Meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.isCompleted {
                        Button(action: {
                            Task {
                                let success = await viewModel.saveChanges()
                                if success { dismiss() }
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                        }
                        .font(.body.bold())
                        .foregroundColor(viewModel.isValid && viewModel.hasChanges ? Theme.accent : Theme.textSecondary.opacity(0.5))
                        .disabled(!viewModel.isValid || !viewModel.hasChanges || viewModel.isLoading)
                    }
                }
            }
            .alert("Excluir meta", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { showingDeleteAlert = false }
                Button("Excluir", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteGoal()
                        if success { dismiss() }
                    }
                }
            } message: {
                Text("Tem certeza que deseja excluir esta meta? Esta ação não pode ser desfeita.")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .tint(Theme.accent)
                    }
                }
            }
        }
    }
}
