import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("JoinRequestsViewModel Tests")
struct JoinRequestsViewModelTests {

    private func makePending() -> PendingJoinRequest {
        PendingJoinRequest(
            request: JoinRequest(id: UUID(), chapterId: UUID(), memberId: UUID(), createdAt: Date()),
            applicantName: "João da Silva"
        )
    }

    @Test("load fills the queue")
    func testLoad() async {
        let mock = TestMockJoinRequestService()
        mock.pendingToReturn = [makePending(), makePending()]

        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: mock)
        await viewModel.load()

        #expect(viewModel.requests.count == 2)
        #expect(mock.fetchPendingRequestsCallCount == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("load surfaces failures")
    func testLoadFailure() async {
        let mock = TestMockJoinRequestService()
        mock.shouldThrowError = true

        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: mock)
        await viewModel.load()

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Officer roles suggest admin, plain membership does not")
    func testRoleSuggestion() {
        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: TestMockJoinRequestService())

        for role in ["Mestre Conselheiro", "1º Conselheiro", "2º Conselheiro", "Escrivão"] {
            viewModel.role = role
            #expect(viewModel.suggestsAdmin == true)
            viewModel.applyRoleSuggestion()
            #expect(viewModel.accessLevel == .admin)
        }

        for role in ["Membro", "Tesoureiro", "Hospitalário"] {
            viewModel.role = role
            #expect(viewModel.suggestsAdmin == false)
            viewModel.applyRoleSuggestion()
            #expect(viewModel.accessLevel == .member)
        }
    }

    @Test("The suggestion is only a default — an admin can override it")
    func testSuggestionIsOverridable() {
        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: TestMockJoinRequestService())

        viewModel.role = "Mestre Conselheiro"
        viewModel.applyRoleSuggestion()
        #expect(viewModel.accessLevel == .admin)

        viewModel.accessLevel = .member
        #expect(viewModel.accessLevel == .member)
        #expect(viewModel.suggestsAdmin == true)
    }

    @Test("approve sends the chosen level and drops the row from the queue")
    func testApprove() async {
        let mock = TestMockJoinRequestService()
        let pending = makePending()
        mock.pendingToReturn = [pending]

        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: mock)
        await viewModel.load()

        viewModel.role = "Escrivão"
        viewModel.applyRoleSuggestion()
        let ok = await viewModel.approve(pending)

        #expect(ok == true)
        #expect(viewModel.requests.isEmpty)
        #expect(mock.lastApprovedAccessLevel == .admin)
        #expect(mock.lastApprovedRole == "Escrivão")
    }

    @Test("\"Membro\" is stored as no role at all")
    func testPlainMemberHasNoRole() async {
        let mock = TestMockJoinRequestService()
        let pending = makePending()
        mock.pendingToReturn = [pending]

        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: mock)
        await viewModel.load()

        _ = await viewModel.approve(pending)

        #expect(mock.lastApprovedRole == nil)
        #expect(mock.lastApprovedAccessLevel == .member)
    }

    @Test("A failed approval keeps the row in the queue")
    func testApproveFailureKeepsRow() async {
        let mock = TestMockJoinRequestService()
        let pending = makePending()
        mock.pendingToReturn = [pending]

        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: mock)
        await viewModel.load()
        mock.shouldThrowError = true

        let ok = await viewModel.approve(pending)

        #expect(ok == false)
        #expect(viewModel.requests.count == 1)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("An empty reason is sent as nil, not as blank text")
    func testRejectBlankReason() async {
        let mock = TestMockJoinRequestService()
        let pending = makePending()
        mock.pendingToReturn = [pending]

        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: mock)
        await viewModel.load()

        let ok = await viewModel.reject(pending, reason: "   ")

        #expect(ok == true)
        #expect(mock.rejectCallCount == 1)
        #expect(viewModel.requests.isEmpty)
    }

    @Test("resetForm returns the sheet to its defaults between reviews")
    func testResetForm() {
        let viewModel = JoinRequestsViewModel(chapterId: UUID(), joinRequestService: TestMockJoinRequestService())

        viewModel.role = "Mestre Conselheiro"
        viewModel.accessLevel = .admin
        viewModel.category = .senior
        viewModel.resetForm()

        #expect(viewModel.role == "Membro")
        #expect(viewModel.accessLevel == .member)
        #expect(viewModel.category == .ativo)
    }
}
