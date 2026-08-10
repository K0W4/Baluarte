import SwiftUI

public struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateEventViewModel
    @State private var showDiscardAlert = false
    
    private var hasUnsavedChanges: Bool {
        !viewModel.title.isEmpty || !viewModel.notes.isEmpty
    }
    
    enum FocusField { case title, notes }
    @FocusState private var focusedField: FocusField?
    
    public init(chapterId: UUID, initialDate: Date? = nil) {
        self._viewModel = State(initialValue: CreateEventViewModel(chapterId: chapterId, initialDate: initialDate))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título do Evento", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .notes }
                    
                    Picker("Tipo", selection: $viewModel.eventType) {
                        ForEach(viewModel.eventTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Data")
                        Spacer()
                        DatePicker("", selection: $viewModel.scheduledDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Horário")
                        Spacer()
                        DatePicker("", selection: $viewModel.scheduledDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                } header: {
                    Text("Informações Básicas")
                }
                
                Section {
                    TextField("Detalhes do evento (opcional)", text: $viewModel.notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .lineLimit(3...6)
                } header: {
                    Text("Detalhes")
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
            .navigationTitle("Novo evento")
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
                            let success = await viewModel.saveEvent()
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
                    .accessibilityLabel("Salvar evento")
                }
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
            .alert("Descartar evento?", isPresented: $showDiscardAlert) {
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
                            Text("Criando evento...")
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
    CreateEventView(chapterId: UUID())
}
