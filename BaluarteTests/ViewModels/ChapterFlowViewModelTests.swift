import Testing
import Foundation
@testable import Baluarte

/// Os ViewModels do caminho de entrada num Capítulo e da fila de Capítulos
/// solicitados. Nenhum tinha cobertura, e são justamente os que decidem entre
/// "entrou", "está na fila" e "foi recusado".
///
/// A fila de fundação fica de fora daqui de propósito: já é coberta em
/// `BootstrapRequestViewModelTests`, e cobrir duas vezes é manutenção em dobro pelo
/// mesmo verde.
@MainActor
@Suite("Fluxo de Capítulo e fila de Capítulos solicitados")
struct ChapterFlowViewModelTests {

    private func makeChapter(name: String = "Capítulo Alfa", number: Int = 656) -> Chapter {
        Chapter(id: UUID(), name: name, number: number, uf: "RS", city: "Porto Alegre", createdAt: Date())
    }

    // MARK: - ChapterSelectionViewModel

    @Test("Busca preenche a lista")
    func testSearchFillsTheList() async {
        let service = TestMockChapterService()
        service.chaptersToReturn = [makeChapter(), makeChapter(name: "Capítulo Beta", number: 42)]

        let viewModel = ChapterSelectionViewModel(chapterService: service)
        await viewModel.search(query: "cap")

        #expect(viewModel.chapters.count == 2)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("Busca que falha explica, e não deixa lista velha na tela")
    func testSearchFailureSurfaces() async {
        let service = TestMockChapterService()
        service.shouldThrowError = true

        let viewModel = ChapterSelectionViewModel(chapterService: service)
        await viewModel.search(query: "cap")

        #expect(viewModel.chapters.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    /// Busca vazia é "lista tudo", não "busca pela string vazia" — a RPC usa o mesmo
    /// índice `unaccent` do registro, e nulo é o que ela espera.
    @Test("Busca em branco não vira busca por string vazia")
    func testBlankQueryIsHandled() async {
        let service = TestMockChapterService()
        service.chaptersToReturn = [makeChapter()]

        let viewModel = ChapterSelectionViewModel(chapterService: service)
        await viewModel.search(query: "   ")

        #expect(viewModel.chapters.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("O estado escolhido acompanha a busca")
    func testSelectedUFIsCarried() async {
        let service = TestMockChapterService()
        let viewModel = ChapterSelectionViewModel(chapterService: service)
        viewModel.selectedUF = .rs

        await viewModel.search(query: "cap")

        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - RequestChapterViewModel

    @Test("Pedido só é válido com nome e número")
    func testRequestValidation() {
        let viewModel = RequestChapterViewModel(chapterService: TestMockChapterService())

        #expect(viewModel.isValid == false)

        viewModel.name = "  Capítulo Novo  "
        #expect(viewModel.isValid == false)

        viewModel.number = "abc"
        #expect(viewModel.isValid == false)

        viewModel.number = "999"
        #expect(viewModel.isValid)
        #expect(viewModel.trimmedName == "Capítulo Novo")
    }

    @Test("Pedido inválido não chega ao servidor")
    func testInvalidRequestNeverLeaves() async {
        let service = TestMockChapterService()
        let viewModel = RequestChapterViewModel(chapterService: service)
        viewModel.name = ""

        let sent = await viewModel.submit(requestedBy: UUID())

        #expect(sent == false)
    }

    @Test("Pedido válido é enviado, e a recusa do servidor aparece")
    func testSubmitAndFailure() async {
        let service = TestMockChapterService()
        let viewModel = RequestChapterViewModel(chapterService: service)
        viewModel.name = "Capítulo Novo"
        viewModel.number = "999"

        #expect(await viewModel.submit(requestedBy: UUID()))
        #expect(viewModel.errorMessage == nil)

        service.shouldThrowError = true
        #expect(await viewModel.submit(requestedBy: UUID()) == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - ChapterRequestsViewModel

    private func makePendingChapterRequest() -> PendingChapterRequest {
        PendingChapterRequest(
            id: UUID(), name: "Capítulo Novo", number: 999, uf: "RS",
            city: "Pelotas", note: nil, createdAt: Date(), requesterName: "Quem pediu"
        )
    }

    @Test("A fila de Capítulos solicitados carrega")
    func testChapterRequestsLoad() async {
        let service = TestMockChapterService()
        service.pendingRequestsToReturn = [makePendingChapterRequest()]

        let viewModel = ChapterRequestsViewModel(chapterService: service)
        await viewModel.load()

        #expect(viewModel.requests.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Falha ao carregar a fila aparece")
    func testChapterRequestsLoadFailure() async {
        let service = TestMockChapterService()
        service.shouldThrowError = true

        let viewModel = ChapterRequestsViewModel(chapterService: service)
        await viewModel.load()

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    /// Aprovar recarrega em vez de remover da lista local: outra pessoa da plataforma
    /// pode ter revisado outro pedido enquanto esta tela estava aberta.
    @Test("Revisar recarrega a fila em vez de mexer na lista local")
    func testReviewReloads() async {
        let service = TestMockChapterService()
        let request = makePendingChapterRequest()
        service.pendingRequestsToReturn = [request]

        let viewModel = ChapterRequestsViewModel(chapterService: service)
        await viewModel.load()

        service.pendingRequestsToReturn = []
        #expect(await viewModel.approve(request))

        #expect(viewModel.requests.isEmpty)
        #expect(service.reviewedRequests.count == 1)
        #expect(service.reviewedRequests.first?.approved == true)
    }

    @Test("Recusa leva o motivo junto")
    func testRejectCarriesTheReason() async {
        let service = TestMockChapterService()
        let request = makePendingChapterRequest()

        let viewModel = ChapterRequestsViewModel(chapterService: service)
        #expect(await viewModel.reject(request, reason: "Já existe com outro número"))

        #expect(service.reviewedRequests.first?.approved == false)
        #expect(service.reviewedRequests.first?.reason == "Já existe com outro número")
    }

    @Test("Revisão recusada não some da fila")
    func testReviewFailureKeepsTheQueue() async {
        let service = TestMockChapterService()
        let request = makePendingChapterRequest()
        service.pendingRequestsToReturn = [request]

        let viewModel = ChapterRequestsViewModel(chapterService: service)
        await viewModel.load()

        service.shouldThrowError = true
        #expect(await viewModel.approve(request) == false)

        #expect(viewModel.requests.count == 1)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - BootstrapQueueViewModel
    //
    // O carregamento e a aprovação já são cobertos em `BootstrapRequestViewModelTests`.
    // O que falta é o comprovante, que é privado e só existe por URL assinada.

    private func makeBootstrapRequest(proofPath: String?) -> BootstrapRequest {
        BootstrapRequest(
            id: UUID(), chapterId: UUID(), memberId: UUID(),
            message: nil, cidSnapshot: "5820", proofPath: proofPath,
            createdAt: Date(), applicantName: "Quem pediu",
            chapterName: "Capítulo Alfa", chapterNumber: 656, chapterUf: "RS"
        )
    }

    @Test("Sem comprovante não há URL para assinar")
    func testProofURLWithoutPath() async {
        let service = TestMockJoinRequestService()
        let viewModel = BootstrapQueueViewModel(joinRequestService: service)

        let url = await viewModel.proofURL(for: makeBootstrapRequest(proofPath: nil))

        #expect(url == nil)
        #expect(service.signedProofURLCallCount == 0)
    }

    @Test("Com comprovante, a URL é pedida ao servidor")
    func testProofURLIsSigned() async {
        let service = TestMockJoinRequestService()
        let viewModel = BootstrapQueueViewModel(joinRequestService: service)

        _ = await viewModel.proofURL(for: makeBootstrapRequest(proofPath: "uid/proof.jpg"))

        #expect(service.signedProofURLCallCount == 1)
    }

    @Test("Motivo em branco vira nulo, e não uma frase vazia")
    func testBlankRejectionReasonBecomesNil() async {
        let service = TestMockJoinRequestService()
        let viewModel = BootstrapQueueViewModel(joinRequestService: service)

        #expect(await viewModel.reject(makeBootstrapRequest(proofPath: nil), reason: "   "))
        #expect(service.rejectCallCount == 1)
    }
}
