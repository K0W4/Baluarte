import SwiftUI

public struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EventDetailViewModel
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    
    public init(event: Event, currentMembershipId: UUID) {
        self._viewModel = State(initialValue: EventDetailViewModel(event: event, currentMembershipId: currentMembershipId))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título do Evento", text: $viewModel.title)
                    
                    // Em leitura, texto -- e não um `Picker` desligado. `.disabled` esmaece
                    // o `Picker` e **não** o `DatePicker`, então no mesmo cartão o tipo do
                    // evento saía a 1,72:1 contra o branco enquanto a data ficava a 21:1.
                    // O tipo é dado real, e era o único campo que parecia ausente.
                    if isEditing {
                        Picker("Tipo", selection: $viewModel.eventType) {
                            ForEach(viewModel.eventTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    } else {
                        LabeledContent("Tipo", value: viewModel.eventType)
                    }
                    
                    DatePicker("Data", selection: $viewModel.scheduledDate, displayedComponents: .date)
                    DatePicker("Horário", selection: $viewModel.scheduledDate, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Informações Básicas")
                }
                .disabled(!isEditing)
                
                Section {
                    TextField("Observações (Opcional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Detalhes")
                }
                .disabled(!isEditing)
                
                Section {
                    AttendanceButton(isConfirmed: viewModel.isUserConfirmed, title: viewModel.title) {
                        Task {
                            HapticManager.shared.impact(style: viewModel.isUserConfirmed ? .rigid : .medium)
                            await viewModel.toggleAttendance()
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                if !viewModel.activeMembers.isEmpty || !viewModel.seniorMembers.isEmpty || !viewModel.advisoryCouncil.isEmpty {
                    Section {
                        if !viewModel.activeMembers.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Ativos (\(viewModel.activeMembers.count))")
                                    .font(Typography.caption1.bold())
                                    .foregroundColor(Theme.textSecondary)
                                ForEach(viewModel.activeMembers) { member in
                                    Text(member.fullName)
                                        .font(Typography.body)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        
                        if !viewModel.seniorMembers.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Sêniors (\(viewModel.seniorMembers.count))")
                                    .font(Typography.caption1.bold())
                                    .foregroundColor(Theme.textSecondary)
                                ForEach(viewModel.seniorMembers) { member in
                                    Text(member.fullName)
                                        .font(Typography.body)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        
                        if !viewModel.advisoryCouncil.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Conselho Consultivo (\(viewModel.advisoryCouncil.count))")
                                    .font(Typography.caption1.bold())
                                    .foregroundColor(Theme.textSecondary)
                                ForEach(viewModel.advisoryCouncil) { member in
                                    Text(member.fullName)
                                        .font(Typography.body)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    } header: {
                        Text("Presenças Confirmadas (\(viewModel.activeMembers.count + viewModel.seniorMembers.count + viewModel.advisoryCouncil.count))")
                    }
                }
                
                Section {
                    Button(action: {
                        HapticManager.shared.notification(type: .warning)
                        showingDeleteAlert = true
                    }) {
                        Text("Excluir evento")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
                .requires(.manageEvents)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(Theme.destructive)
                            .font(Typography.caption1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Detalhes do Evento")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadMembers()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .accessibilityLabel("Fechar")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button(action: {
                            HapticManager.shared.impact(style: .medium)
                            Task {
                                let success = await viewModel.saveChanges()
                                if success { 
                                    isEditing = false 
                                }
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                        }
                        .font(.body.bold())
                        .foregroundColor(viewModel.isValid && viewModel.hasChanges ? Theme.accent : Theme.textSecondary.opacity(0.5))
                        .disabled(!viewModel.isValid || !viewModel.hasChanges || viewModel.isLoading)
                        .accessibilityLabel("Salvar alterações")
                    } else {
                        Button(action: {
                            HapticManager.shared.impact(style: .light)
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .accessibilityLabel("Editar")
                        .requires(.manageEvents)
                    }
                }
            }
            .alert("Excluir evento", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { showingDeleteAlert = false }
                Button("Excluir", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteEvent()
                        if success { dismiss() }
                    }
                }
            } message: {
                Text("Tem certeza que deseja excluir este evento? Esta ação não pode ser desfeita.")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: Spacing.sm) {
                            ProgressView()
                                .tint(Theme.accent)
                            Text("Salvando...")
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
