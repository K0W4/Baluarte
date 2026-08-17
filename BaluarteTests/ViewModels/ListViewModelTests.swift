import Testing
import Foundation
@testable import Baluarte

/// As três listas principais. O que elas têm de lógica não é o carregamento — é o
/// filtro, e é ele que decide o que uma pessoa vê como sendo dela.
@MainActor
@Suite("Listas: Membros, Tarefas e Calendário")
struct ListViewModelTests {

    // MARK: - MembersViewModel

    private func makeMember(
        name: String,
        role: String? = nil,
        isActive: Bool = true,
        isSenior: Bool = false,
        isMason: Bool = false
    ) -> Member {
        Member(
            id: UUID(), chapterId: UUID(), fullName: name, role: role,
            isActive: isActive, isSenior: isSenior, isMason: isMason,
            accessLevel: "member", createdAt: Date()
        )
    }

    private func makeMembersViewModel(_ members: [Member]) async -> MembersViewModel {
        let service = TestMockMemberService()
        service.membersToReturn = members
        let viewModel = MembersViewModel(memberService: service)
        viewModel.currentChapterId = UUID()
        await viewModel.loadMembers()
        return viewModel
    }

    @Test("Sem Capítulo aberto, não se busca ninguém")
    func testMembersWithoutChapter() async {
        let service = TestMockMemberService()
        service.membersToReturn = [makeMember(name: "Alguém")]

        let viewModel = MembersViewModel(memberService: service)
        await viewModel.loadMembers()

        #expect(service.fetchMembersCallCount == 0)
        #expect(viewModel.allMembers.isEmpty)
    }

    @Test("A lista sai em ordem alfabética")
    func testMembersAreSortedByName() async {
        let viewModel = await makeMembersViewModel([
            makeMember(name: "Zacarias"),
            makeMember(name: "Alberto"),
            makeMember(name: "Marcos")
        ])

        #expect(viewModel.filteredMembers.map(\.fullName) == ["Alberto", "Marcos", "Zacarias"])
    }

    @Test("Cada filtro recorta a categoria certa")
    func testMembersFilters() async {
        let viewModel = await makeMembersViewModel([
            makeMember(name: "Ativo", isActive: true),
            makeMember(name: "Sênior", isActive: false, isSenior: true),
            makeMember(name: "Maçom", isActive: false, isMason: true)
        ])

        viewModel.selectedFilter = .todos
        #expect(viewModel.filteredMembers.count == 3)

        viewModel.selectedFilter = .ativos
        #expect(viewModel.filteredMembers.map(\.fullName) == ["Ativo"])

        viewModel.selectedFilter = .seniors
        #expect(viewModel.filteredMembers.map(\.fullName) == ["Sênior"])

        viewModel.selectedFilter = .macons
        #expect(viewModel.filteredMembers.map(\.fullName) == ["Maçom"])
    }

    @Test("A busca alcança nome e cargo, sem ligar para maiúscula")
    func testMembersSearch() async {
        let viewModel = await makeMembersViewModel([
            makeMember(name: "Alberto", role: "Escrivão"),
            makeMember(name: "Marcos", role: "Tesoureiro")
        ])

        viewModel.searchText = "alberto"
        #expect(viewModel.filteredMembers.map(\.fullName) == ["Alberto"])

        viewModel.searchText = "TESOUREIRO"
        #expect(viewModel.filteredMembers.map(\.fullName) == ["Marcos"])

        viewModel.searchText = "não existe"
        #expect(viewModel.filteredMembers.isEmpty)
    }

    @Test("Falha ao carregar membros aparece")
    func testMembersLoadFailure() async {
        let service = TestMockMemberService()
        service.shouldThrowError = true

        let viewModel = MembersViewModel(memberService: service)
        viewModel.currentChapterId = UUID()
        await viewModel.loadMembers()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.allMembers.isEmpty)
    }

    // MARK: - TasksViewModel

    private func makeTask(
        title: String,
        creatorId: UUID,
        assigneeId: UUID? = nil,
        committeeId: UUID? = nil,
        isCompleted: Bool = false
    ) -> ChapterTask {
        ChapterTask(
            id: UUID(), chapterId: UUID(), creatorId: creatorId,
            assigneeId: assigneeId, committeeId: committeeId,
            title: title, description: "", isCompleted: isCompleted, createdAt: Date()
        )
    }

    private func makeTasksViewModel(
        tasks: [ChapterTask],
        committees: [Committee] = [],
        me: UUID
    ) async -> (TasksViewModel, TestMockTaskService) {
        let taskService = TestMockTaskService()
        taskService.tasksToReturn = tasks
        let committeeService = TestMockCommitteeService()
        committeeService.committeesToReturn = committees

        let viewModel = TasksViewModel(taskService: taskService, committeeService: committeeService)
        viewModel.currentChapterId = UUID()
        viewModel.currentMembershipId = me
        await viewModel.loadData()
        return (viewModel, taskService)
    }

    @Test("Sem Capítulo aberto, nada é buscado")
    func testTasksWithoutChapter() async {
        let taskService = TestMockTaskService()
        let viewModel = TasksViewModel(taskService: taskService, committeeService: TestMockCommitteeService())

        await viewModel.loadData()

        #expect(taskService.fetchTasksCallCount == 0)
    }

    /// "Minhas" é quem criou ou para quem foi atribuída — o vínculo, nunca a conta.
    @Test("Minhas tarefas são as que eu criei ou recebi")
    func testMineSegmentFiltersByMembership() async {
        let me = UUID()
        let someoneElse = UUID()
        let (viewModel, _) = await makeTasksViewModel(tasks: [
            makeTask(title: "Minha por autoria", creatorId: me),
            makeTask(title: "Minha por atribuição", creatorId: someoneElse, assigneeId: me),
            makeTask(title: "De outra pessoa", creatorId: someoneElse, assigneeId: someoneElse)
        ], me: me)

        viewModel.selectedSegment = .minhas
        #expect(viewModel.displayIndividualTasks.count == 2)

        viewModel.selectedSegment = .gerais
        #expect(viewModel.displayIndividualTasks.isEmpty)
    }

    @Test("Tarefa de comissão é agrupada pela comissão")
    func testCommitteeGrouping() async {
        let me = UUID()
        let committeeId = UUID()
        let (viewModel, _) = await makeTasksViewModel(tasks: [
            makeTask(title: "Da comissão", creatorId: me, committeeId: committeeId),
            makeTask(title: "Solta", creatorId: me)
        ], me: me)

        #expect(viewModel.committeeTasks[committeeId]?.count == 1)
        #expect(viewModel.generalTasks.count == 1)
    }

    @Test("Concluída sai das ativas")
    func testCompletedLeavesTheActiveList() async {
        let me = UUID()
        let (viewModel, _) = await makeTasksViewModel(tasks: [
            makeTask(title: "Feita", creatorId: me, isCompleted: true),
            makeTask(title: "Pendente", creatorId: me)
        ], me: me)

        #expect(viewModel.activeTasks.count == 1)
        #expect(viewModel.completedTasks.count == 1)
    }

    @Test("Marcar como concluída aplica na hora")
    func testToggleIsOptimistic() async {
        let me = UUID()
        let task = makeTask(title: "Pendente", creatorId: me)
        let (viewModel, service) = await makeTasksViewModel(tasks: [task], me: me)

        await viewModel.toggleTaskCompletion(task: task)

        #expect(viewModel.allTasks.first?.isCompleted == true)
        #expect(service.toggleTaskCompletionCallCount == 1)
    }

    @Test("Marcação recusada volta atrás")
    func testToggleRevertsOnFailure() async {
        let me = UUID()
        let task = makeTask(title: "Pendente", creatorId: me)
        let (viewModel, service) = await makeTasksViewModel(tasks: [task], me: me)

        service.shouldThrowError = true
        await viewModel.toggleTaskCompletion(task: task)

        #expect(viewModel.allTasks.first?.isCompleted == false)
    }

    @Test("Excluir some da lista, e volta se o servidor recusar")
    func testDeleteRevertsOnFailure() async {
        let me = UUID()
        let task = makeTask(title: "Pendente", creatorId: me)
        let (viewModel, service) = await makeTasksViewModel(tasks: [task], me: me)

        service.shouldThrowError = true
        await viewModel.deleteTask(task: task)

        #expect(viewModel.allTasks.count == 1)
    }

    @Test("Comissão sem nome conhecido não mostra UUID")
    func testCommitteeNameFallback() async {
        let me = UUID()
        let committee = Committee(
            id: UUID(), chapterId: UUID(), name: "Filantropia",
            chairmanId: nil, memberIds: nil, createdAt: Date()
        )
        let (viewModel, _) = await makeTasksViewModel(tasks: [], committees: [committee], me: me)

        #expect(viewModel.committeeName(for: committee.id) == "Filantropia")
        #expect(viewModel.committeeName(for: UUID()) == String(localized: "Comissão"))
    }

    // MARK: - CalendarViewModel

    private func makeEvent(on date: Date, attendees: [UUID]? = nil) -> Event {
        Event(
            id: UUID(), chapterId: UUID(), title: "Reunião",
            scheduledDate: date, eventType: "Ritualística",
            confirmedAttendees: attendees, createdAt: Date()
        )
    }

    @Test("Eventos são recortados por dia")
    func testEventsForDay() async {
        let service = TestMockEventService()
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        service.eventsToReturn = [makeEvent(on: today), makeEvent(on: tomorrow)]

        let viewModel = CalendarViewModel(eventService: service)
        viewModel.currentChapterId = UUID()
        await viewModel.loadEvents()

        #expect(viewModel.events(for: today).count == 1)
        #expect(viewModel.hasEvents(for: today))
        #expect(viewModel.hasEvents(for: Calendar.current.date(byAdding: .day, value: 5, to: today) ?? today) == false)
    }

    /// A presença é do vínculo. Comparar com a conta faria a lista dizer que ninguém
    /// confirmou nada.
    @Test("Presença é conferida contra o vínculo")
    func testAttendanceIsCheckedAgainstMembership() async {
        let me = UUID()
        let service = TestMockEventService()
        service.eventsToReturn = [makeEvent(on: Date(), attendees: [me])]

        let viewModel = CalendarViewModel(eventService: service)
        viewModel.currentChapterId = UUID()
        viewModel.currentMembershipId = me
        await viewModel.loadEvents()

        let event = viewModel.events.first
        #expect(event.map { viewModel.isUserConfirmed(for: $0) } == true)

        viewModel.currentMembershipId = UUID()
        #expect(event.map { viewModel.isUserConfirmed(for: $0) } == false)
    }

    @Test("Confirmar e desconfirmar chamam lados opostos do serviço")
    func testConfirmAndRemoveAttendance() async {
        let me = UUID()
        let service = TestMockEventService()
        let event = makeEvent(on: Date())
        service.eventsToReturn = [event]

        let viewModel = CalendarViewModel(eventService: service)
        viewModel.currentChapterId = UUID()
        viewModel.currentMembershipId = me
        await viewModel.loadEvents()

        await viewModel.confirmAttendance(eventId: event.id)
        #expect(service.confirmAttendanceCallCount == 1)
        #expect(viewModel.events.first?.confirmedAttendees?.contains(me) == true)

        await viewModel.confirmAttendance(eventId: event.id)
        #expect(service.removeAttendanceCallCount == 1)
        #expect(viewModel.events.first?.confirmedAttendees?.contains(me) == false)
    }

    @Test("Confirmação recusada devolve a lista ao que era")
    func testAttendanceRevertsOnFailure() async {
        let me = UUID()
        let service = TestMockEventService()
        let event = makeEvent(on: Date())
        service.eventsToReturn = [event]

        let viewModel = CalendarViewModel(eventService: service)
        viewModel.currentChapterId = UUID()
        viewModel.currentMembershipId = me
        await viewModel.loadEvents()

        service.shouldThrowError = true
        await viewModel.confirmAttendance(eventId: event.id)

        #expect(viewModel.events.first?.confirmedAttendees?.contains(me) != true)
    }

    @Test("Sem vínculo, confirmar não faz nada")
    func testAttendanceWithoutMembership() async {
        let service = TestMockEventService()
        let event = makeEvent(on: Date())
        service.eventsToReturn = [event]

        let viewModel = CalendarViewModel(eventService: service)
        viewModel.currentChapterId = UUID()
        await viewModel.loadEvents()

        await viewModel.confirmAttendance(eventId: event.id)

        #expect(service.confirmAttendanceCallCount == 0)
    }
}
