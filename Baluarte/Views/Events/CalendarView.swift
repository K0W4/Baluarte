import SwiftUI

public struct CalendarView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.permissions) private var permissions
    @State private var viewModel = CalendarViewModel()
    @State private var monthTransitionDirection: Edge = .trailing
    @State private var showingCreateEvent = false
    @State private var selectedEvent: Event?

    private let calendar = Calendar.current

    /// Os símbolos vêm do `Calendar`, não de uma lista fixa: `daysInMonth()` monta a grade
    /// com `dateInterval(of: .weekOfMonth)`, que respeita o `firstWeekday` da região. Com o
    /// cabeçalho fixo em domingo, quem usa o iPhone em Portugal, Espanha ou Reino Unido via
    /// a grade começar na segunda e o cabeçalho dizer "Dom" na primeira coluna — todo dia
    /// do mês rotulado com o dia da semana errado.
    private var daysInWeek: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        guard offset > 0, offset < symbols.count else { return symbols }
        return Array(symbols[offset...] + symbols[..<offset])
    }

    /// Identidade do mês, não do instante. `currentMonth` é um `Date` completo e nunca
    /// normalizado, então qualquer reatribuição de uma data do mesmo mês recriava o grid
    /// inteiro e disparava a transição de troca de mês sem mês nenhum ter mudado.
    private var currentMonthIdentity: Int {
        let parts = calendar.dateComponents([.year, .month], from: viewModel.currentMonth)
        return (parts.year ?? 0) * 12 + (parts.month ?? 0)
    }

    private var createEventAction: (() -> Void)? {
        permissions.can(.manageEvents) ? { showingCreateEvent = true } : nil
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(
                            message: errorMessage,
                            onRetry: {
                                Task { await viewModel.loadEvents() }
                            },
                            onDismiss: {
                                withAnimation { viewModel.errorMessage = nil }
                            }
                        )
                        .padding(.horizontal, Spacing.screenEdgePadding)
                    }
                    
                    calendarHeader
                    daysGrid
                        .id(currentMonthIdentity)
                        .transition(.push(from: monthTransitionDirection))
                    eventsList
                }
                .padding(.vertical, Spacing.lg)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 100, for: .scrollContent)
            .background(Theme.backgroundPrimary)
            .navigationTitle("Calendário")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hoje") {
                        HapticManager.shared.impact(style: .light)
                        let today = Date()
                        withAnimation {
                            viewModel.selectedDate = today
                        }
                        if !Calendar.current.isDate(viewModel.currentMonth, equalTo: today, toGranularity: .month) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentMonth = today
                            }
                        }
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(Calendar.current.isDateInToday(viewModel.selectedDate) && Calendar.current.isDate(viewModel.currentMonth, equalTo: Date(), toGranularity: .month))
                }
            }
            .tint(Theme.accent)
        .refreshable {
                await viewModel.loadEvents()
            }
            .task {
                viewModel.currentMembershipId = authViewModel.currentMembershipId
                viewModel.currentChapterId = authViewModel.currentChapterId
                await viewModel.loadEvents()
            }
            .onAppear {
                viewModel.currentMembershipId = authViewModel.currentMembershipId
                viewModel.currentChapterId = authViewModel.currentChapterId
                Task {
                    await viewModel.loadEvents(showLoading: false)
                }
            }
            .sheet(isPresented: $showingCreateEvent, onDismiss: {
                Task { await viewModel.loadEvents() }
            }) {
                if let chapterId = authViewModel.currentChapterId {
                    CreateEventView(chapterId: chapterId, initialDate: viewModel.selectedDate)
                }
            }
            .sheet(item: $selectedEvent, onDismiss: {
                Task { await viewModel.loadEvents() }
            }) { event in
                if let currentMembershipId = authViewModel.currentMembershipId {
                    EventDetailView(event: event, currentMembershipId: currentMembershipId)
                }
            }
        }
    }
    
    private var calendarHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.title3)
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Mês anterior")
            .accessibilityHint("Toca duas vezes para retroceder um mês")
            
            Spacer()
            
            Text(monthYearString(for: viewModel.currentMonth))
                .font(Typography.title2)
                .bold()
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(Typography.title3)
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Próximo mês")
            .accessibilityHint("Toca duas vezes para avançar um mês")
        }
        .padding(.horizontal, Spacing.screenEdgePadding)
    }
    
    private var daysGrid: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(Typography.subheadline)
                        .bold()
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.md) {
                ForEach(daysInMonth()) { slot in
                    if let date = slot.date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                            hasEvents: viewModel.hasEvents(for: date)
                        ) {
                            HapticManager.shared.impact(style: .light)
                            // Sem `withAnimation` global: ele animava tudo que dependesse
                            // da transação, inclusive a altura do ScrollView e o colapso do
                            // título grande. A célula anima a própria seleção.
                            viewModel.selectedDate = date
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.screenEdgePadding)
    }
    
    private var eventsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderView(
                title: "Eventos do Dia",
                actionLabel: "Adicionar evento",
                actionHint: "Toca duas vezes para adicionar evento no calendário",
                action: createEventAction
            )
            .padding(.horizontal, Spacing.screenEdgePadding)

            let selectedEvents = viewModel.isLoading ? Event.skeletonList : viewModel.events(for: viewModel.selectedDate)

            if selectedEvents.isEmpty && !viewModel.isLoading {
                EmptyStateCard(cardType: .event, action: createEventAction)
                    .padding(.horizontal, Spacing.screenEdgePadding)
            } else {
                ForEach(selectedEvents) { event in
                    EventCard(
                        event: event,
                        isUserConfirmed: viewModel.isUserConfirmed(for: event)
                    ) {
                        if !viewModel.isLoading {
                            Task { await viewModel.confirmAttendance(eventId: event.id) }
                        }
                    }
                    .skeleton(isLoading: viewModel.isLoading)
                    .padding(.horizontal, Spacing.screenEdgePadding)
                    .onTapGesture {
                        selectedEvent = event
                    }
                    .contextMenu {
                            Button {
                                Task {
                                    await viewModel.addToNativeCalendar(event: event)
                                }
                            } label: {
                                Label("Adicionar ao calendário", systemImage: "calendar.badge.plus")
                            }
                        }
                }
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        HapticManager.shared.impact(style: .light)
        monthTransitionDirection = value > 0 ? .trailing : .leading
        if let newMonth = calendar.date(byAdding: .month, value: value, to: viewModel.currentMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.currentMonth = newMonth
            }
        }
    }
    
    private func monthYearString(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    /// Uma célula da grade. Existe por causa da identidade: a grade era um `[Date?]`
    /// percorrido com `id: \.self`, e as células de preenchimento — os dias do mês
    /// anterior e do seguinte — são todas `nil`. Em onze dos doze meses de 2026 isso dava
    /// ids repetidos (agosto e maio, com onze cada), e id duplicado em `ForEach` é
    /// resultado indefinido: a SwiftUI animava células a partir de posições que não eram
    /// as delas. A posição na grade é o que identifica a célula.
    private struct DaySlot: Identifiable {
        let id: Int
        let date: Date?
    }

    private func daysInMonth() -> [DaySlot] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }

        var slots: [DaySlot] = []
        var currentDate = monthFirstWeek.start

        while currentDate < monthLastWeek.end {
            let isThisMonth = calendar.isDate(currentDate, equalTo: viewModel.currentMonth, toGranularity: .month)
            slots.append(DaySlot(id: slots.count, date: isThisMonth ? currentDate : nil))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return slots
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            let isToday = calendar.isDateInToday(date)
            
            VStack(spacing: Spacing.xxs) {
                Text("\(calendar.component(.day, from: date))")
                    .font(Typography.body)
                    .bold(isSelected || isToday)
                    .foregroundColor(isSelected ? Theme.backgroundPrimary : (isToday ? Theme.accent : Theme.textPrimary))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? Theme.accent : Color.clear)
                    )
                
                Circle()
                    .fill(hasEvents ? Theme.accent : Color.clear)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isSelected)
        .accessibilityLabel(accessibilityDateLabel)
        .accessibilityValue(accessibilityStateValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var accessibilityDateLabel: String {
        date.formatted(date: .complete, time: .omitted)
    }

    /// O estado sai do rótulo e vira valor: emendado no nome da data, ele não podia ser
    /// filtrado nem abreviado pelo Braille — e as três palavras eram `String` cruas, então
    /// o app em inglês anunciava "Sunday, March 1, selecionado, com eventos".
    private var accessibilityStateValue: String {
        var states: [String] = []
        if hasEvents { states.append(String(localized: "com eventos")) }
        if calendar.isDateInToday(date) { states.append(String(localized: "hoje")) }
        return states.joined(separator: ", ")
    }
}

#Preview {
    CalendarView()
}
