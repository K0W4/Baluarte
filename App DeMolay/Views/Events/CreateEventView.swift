import SwiftUI

public struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateEventViewModel
    
    public init(chapterId: UUID, initialDate: Date? = nil) {
        self._viewModel = State(initialValue: CreateEventViewModel(chapterId: chapterId, initialDate: initialDate))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título do Evento", text: $viewModel.title)
                    
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
                            .environment(\.locale, Locale(identifier: "pt_BR"))
                    }
                    
                    HStack {
                        Text("Horário")
                        Spacer()
                        DatePicker("", selection: $viewModel.scheduledDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "pt_BR"))
                    }
                } header: {
                    Text("Informações Básicas")
                }
                
                Section {
                    TextField("Detalhes do evento...", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Detalhes")
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
            .navigationTitle("Novo Evento")
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
                            let success = await viewModel.saveEvent()
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
    CreateEventView(chapterId: UUID())
}
