import SwiftUI

public struct CalendarView: View {
    @State private var viewModel = CalendarViewModel()
    @State private var monthTransitionDirection: Edge = .trailing
    @State private var showingCreateEvent = false
    @State private var selectedEvent: Event?
    
    private let calendar = Calendar.current
    private let daysInWeek = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    
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
                        .id(viewModel.currentMonth)
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
            .refreshable {
                await viewModel.loadEvents()
            }
            .task {
                await viewModel.loadEvents()
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(initialDate: viewModel.selectedDate)
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
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
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                            hasEvents: viewModel.hasEvents(for: date)
                        ) {
                            HapticManager.shared.impact(style: .light)
                            withAnimation {
                                viewModel.selectedDate = date
                            }
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
                actionHint: "Toca duas vezes para adicionar evento no calendário"
            ) {
                showingCreateEvent = true
            }
            .padding(.horizontal, Spacing.screenEdgePadding)
            
            let selectedEvents = viewModel.isLoading ? Event.skeletonList : viewModel.events(for: viewModel.selectedDate)
            
            if selectedEvents.isEmpty && !viewModel.isLoading {
                EmptyStateCard(cardType: .event) {
                    showingCreateEvent = true
                }
                    .padding(.horizontal, Spacing.screenEdgePadding)
            } else {
                ForEach(selectedEvents) { event in
                    EventCard(event: event) {
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
                                Label("Adicionar ao Calendário", systemImage: "calendar.badge.plus")
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        var dates: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            if calendar.isDate(currentDate, equalTo: viewModel.currentMonth, toGranularity: .month) {
                dates.append(currentDate)
            } else {
                dates.append(nil)
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return dates
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
    }
}

#Preview {
    CalendarView()
}
