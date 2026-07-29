import SwiftUI

public struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EventDetailViewModel
    @State private var showingDeleteAlert = false
    
    public init(event: Event, currentUserId: UUID) {
        self._viewModel = State(initialValue: EventDetailViewModel(event: event, currentUserId: currentUserId))
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
                    
                    DatePicker("Data", selection: $viewModel.scheduledDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                    DatePicker("Horário", selection: $viewModel.scheduledDate, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                } header: {
                    Text("Informações Básicas")
                }
                
                Section {
                    TextField("Observações (Opcional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Detalhes")
                }
                
                Section {
                    Button(action: {
                        Task {
                            let generator = UIImpactFeedbackGenerator(style: viewModel.isUserConfirmed ? .rigid : .medium)
                            generator.impactOccurred()
                            await viewModel.toggleAttendance()
                        }
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: viewModel.isUserConfirmed ? "checkmark.circle.fill" : "person.crop.circle.badge.plus")
                                .foregroundColor(viewModel.isUserConfirmed ? Theme.success : Theme.accent)
                                .frame(width: 24, height: 24)
                            Text(viewModel.isUserConfirmed ? "Presença confirmada" : "Confirmar presença")
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
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
                        showingDeleteAlert = true
                    }) {
                        Text("Excluir evento")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
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
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .tint(Theme.accent)
                    }
                }
            }
        }
    }
}
