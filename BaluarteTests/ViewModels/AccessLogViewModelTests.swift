import Testing
import Foundation
@testable import Baluarte

@MainActor
@Suite("AccessLogViewModel Tests")
struct AccessLogViewModelTests {

    private func entry(
        id: Int,
        txid: Int = 1,
        action: AccessChangeAction = .accessLevelChanged,
        actorId: UUID? = UUID(),
        actorName: String? = "Fundador",
        subjectName: String? = "João da Silva",
        oldValue: String? = "member",
        newValue: String? = "admin"
    ) -> AccessChangeEntry {
        AccessChangeEntry(
            id: id,
            txid: txid,
            occurredAt: Date(timeIntervalSince1970: 1_770_000_000),
            action: action,
            actorId: actorId,
            actorName: actorName,
            subjectMembershipId: UUID(),
            subjectName: subjectName,
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // MARK: - Carregamento

    @Test("load fills the chapter log")
    func testLoadChapterScope() async {
        let mock = TestMockAuditService()
        let chapterId = UUID()
        mock.pages = [[entry(id: 2), entry(id: 1, txid: 2)]]

        let viewModel = AccessLogViewModel(scope: .chapter(chapterId), auditService: mock)
        await viewModel.load()

        #expect(viewModel.entries.count == 2)
        #expect(mock.chapterLogCallCount == 1)
        #expect(mock.platformLogCallCount == 0)
        #expect(mock.lastChapterId == chapterId)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Platform scope calls the platform function")
    func testLoadPlatformScope() async {
        let mock = TestMockAuditService()
        mock.pages = [[entry(id: 1, action: .platformAdminChanged, oldValue: "false", newValue: "true")]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(mock.platformLogCallCount == 1)
        #expect(mock.chapterLogCallCount == 0)
        #expect(viewModel.rows.first?.event == .platformAdminGranted)
    }

    @Test("A refusal surfaces and leaves the list empty")
    func testLoadFailure() async {
        let mock = TestMockAuditService()
        mock.shouldThrowError = true

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(viewModel.entries.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - Paginação

    @Test("A full page means there may be more")
    func testHasMoreWhenPageIsFull() async {
        let mock = TestMockAuditService()
        mock.pages = [[entry(id: 2), entry(id: 1, txid: 2)]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock, pageSize: 2)
        await viewModel.load()

        #expect(viewModel.hasMore)
    }

    @Test("A short page ends the list")
    func testNoMoreWhenPageIsShort() async {
        let mock = TestMockAuditService()
        mock.pages = [[entry(id: 1)]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock, pageSize: 2)
        await viewModel.load()

        #expect(viewModel.hasMore == false)
    }

    /// O cursor é o id, e não a hora: as duas linhas de uma transferência carregam o
    /// mesmo instante, e paginar por tempo pularia uma delas.
    @Test("loadMore pages from the last id, not from a timestamp")
    func testLoadMoreUsesLastId() async {
        let mock = TestMockAuditService()
        mock.pages = [
            [entry(id: 9), entry(id: 8, txid: 2)],
            [entry(id: 7, txid: 3)]
        ]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock, pageSize: 2)
        await viewModel.load()
        await viewModel.loadMore()

        #expect(mock.requestedBeforeIds == [nil, 8])
        #expect(viewModel.entries.count == 3)
        #expect(viewModel.hasMore == false)
    }

    @Test("loadMore does nothing once the list has ended")
    func testLoadMoreStopsAtTheEnd() async {
        let mock = TestMockAuditService()
        mock.pages = [[entry(id: 1)]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock, pageSize: 2)
        await viewModel.load()
        await viewModel.loadMore()

        #expect(mock.platformLogCallCount == 1)
    }

    // MARK: - Interpretação

    @Test("Rising is a promotion, falling is a demotion")
    func testPromotionAndDemotion() async {
        let mock = TestMockAuditService()
        mock.pages = [[
            entry(id: 2, txid: 2, oldValue: "member", newValue: "admin"),
            entry(id: 1, txid: 1, oldValue: "admin", newValue: "member")
        ]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(viewModel.rows.map(\.event) == [.promoted(to: .admin), .demoted(to: .member)])
    }

    /// Sem valor antigo o vínculo nasceu elevado -- é o caso de quem foi aprovado já
    /// como administrador, e sem ele essa pessoa não teria a quem perguntar.
    @Test("No previous value means the bond was born elevated")
    func testJoinedAlreadyElevated() async {
        let mock = TestMockAuditService()
        mock.pages = [[entry(id: 1, oldValue: nil, newValue: "admin")]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(viewModel.rows.first?.event == .joinedWith(.admin))
    }

    /// Duas mudanças na mesma transação, uma saindo de Fundador e outra entrando, são
    /// uma transferência -- e não um rebaixamento seguido de promoção, que é como o
    /// par apareceria se cada linha fosse lida sozinha.
    @Test("The pair in one transaction collapses into a transfer")
    func testOwnershipTransferCollapses() async {
        let mock = TestMockAuditService()
        mock.pages = [[
            entry(id: 5, txid: 77, subjectName: "Novo Fundador", oldValue: "admin", newValue: "owner"),
            entry(id: 4, txid: 77, subjectName: "Antigo Fundador", oldValue: "owner", newValue: "admin")
        ]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(viewModel.rows.count == 1)
        #expect(viewModel.rows.first?.event == .ownershipTransferred)
        #expect(viewModel.rows.first?.subject == .person("Novo Fundador"))
        #expect(viewModel.rows.first?.id == 5)
    }

    @Test("Two unrelated changes in one transaction stay two rows")
    func testUnrelatedPairIsNotATransfer() async {
        let mock = TestMockAuditService()
        mock.pages = [[
            entry(id: 5, txid: 77, oldValue: "member", newValue: "admin"),
            entry(id: 4, txid: 77, oldValue: "member", newValue: "admin")
        ]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(viewModel.rows.count == 2)
    }

    /// A exclusão de conta rebaixa o vínculo para membro sem ninguém ter mandado. Sem
    /// separar esse caso o log diria "rebaixado por (desconhecido)".
    @Test("Account deletion is not a demotion by somebody")
    func testAccountDeletionIsItsOwnEvent() async {
        let mock = TestMockAuditService()
        mock.pages = [[entry(
            id: 1,
            action: .accessClearedOnAccountDeletion,
            actorId: nil,
            actorName: nil,
            subjectName: "Membro removido",
            oldValue: "admin",
            newValue: "member"
        )]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(viewModel.rows.first?.event == .accessClearedOnAccountDeletion)
        #expect(viewModel.rows.first?.actor == .system)
    }

    /// Ator sem id é o sistema; ator com id e sem nome é conta excluída depois. Tratar
    /// os dois como a mesma coisa apagaria a diferença entre "ninguém fez" e "quem fez
    /// não está mais aqui".
    @Test("A missing actor name is not the same as a missing actor")
    func testRemovedAccountIsNotTheSystem() async {
        let mock = TestMockAuditService()
        mock.pages = [[
            entry(id: 2, txid: 2, actorId: UUID(), actorName: nil),
            entry(id: 1, txid: 1, actorId: nil, actorName: nil)
        ]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        await viewModel.load()

        #expect(viewModel.rows.map(\.actor) == [.removedAccount, .system])
    }

    @Test("An invite has no subject")
    func testInviteRowsHaveNoSubject() async {
        let mock = TestMockAuditService()
        mock.pages = [[
            entry(id: 2, txid: 2, action: .inviteRevoked, subjectName: nil, oldValue: "3", newValue: nil),
            entry(id: 1, txid: 1, action: .inviteDeleted, subjectName: nil, oldValue: "0", newValue: nil)
        ]]

        let viewModel = AccessLogViewModel(scope: .chapter(UUID()), auditService: mock)
        await viewModel.load()

        #expect(viewModel.rows.map(\.event) == [.inviteRevoked, .inviteDeleted])
        #expect(viewModel.rows.allSatisfy { $0.subject == nil })
    }

    @Test("An empty log is empty, a loading one is not")
    func testIsEmpty() async {
        let mock = TestMockAuditService()
        mock.pages = [[]]

        let viewModel = AccessLogViewModel(scope: .platform, auditService: mock)
        #expect(viewModel.isEmpty)

        await viewModel.load()
        #expect(viewModel.isEmpty)
        #expect(viewModel.rows.isEmpty)
    }
}
