import Testing
import Foundation
@testable import Baluarte

/// O convite é a porta larga: um código que viaja por grupo de WhatsApp e sempre
/// concede `member`. O que esta tela decide é prazo, limite de usos e revogação.
@MainActor
@Suite("InviteManagementViewModel Tests")
struct InviteManagementViewModelTests {

    private func makeInvite(
        code: String = "4K7QX2MN",
        expiresAt: Date? = nil,
        maxUses: Int? = nil,
        usesCount: Int = 0,
        revokedAt: Date? = nil
    ) -> ChapterInvite {
        ChapterInvite(
            id: UUID(), chapterId: UUID(), code: code,
            expiresAt: expiresAt, maxUses: maxUses, usesCount: usesCount,
            revokedAt: revokedAt, createdBy: UUID(), createdAt: Date()
        )
    }

    @Test("load traz os convites do Capítulo")
    func testLoad() async {
        let service = TestMockInviteService()
        service.invitesToReturn = [makeInvite(), makeInvite(code: "9PQR3STV")]

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        await viewModel.load()

        #expect(viewModel.invites.count == 2)
        #expect(service.fetchInvitesCallCount == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Falha ao carregar aparece na tela")
    func testLoadFailure() async {
        let service = TestMockInviteService()
        service.shouldThrowError = true

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        await viewModel.load()

        #expect(viewModel.invites.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    /// Vencido, esgotado e revogado são três formas de estar morto, e a tela separa os
    /// vivos dos mortos — mostrar um código que não funciona mais é convidar alguém a
    /// mandá-lo para o grupo.
    @Test("Vivos e mortos ficam em listas separadas")
    func testActiveAndInactiveSplit() async {
        let service = TestMockInviteService()
        service.invitesToReturn = [
            makeInvite(code: "AAAAAAAA"),
            makeInvite(code: "BBBBBBBB", expiresAt: Date(timeIntervalSince1970: 0)),
            makeInvite(code: "CCCCCCCC", maxUses: 2, usesCount: 2),
            makeInvite(code: "DDDDDDDD", revokedAt: Date())
        ]

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        await viewModel.load()

        #expect(viewModel.activeInvites.count == 1)
        #expect(viewModel.inactiveInvites.count == 3)
    }

    @Test("Sem limite de usos, nenhum limite é enviado")
    func testCreateWithoutUsageLimit() async {
        let service = TestMockInviteService()
        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        viewModel.limitUses = false
        viewModel.maxUses = 30

        _ = await viewModel.create(createdBy: UUID())

        #expect(service.lastCreatedMaxUses == nil)
    }

    @Test("Com limite de usos, o número escolhido é enviado")
    func testCreateWithUsageLimit() async {
        let service = TestMockInviteService()
        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        viewModel.limitUses = true
        viewModel.maxUses = 5

        _ = await viewModel.create(createdBy: UUID())

        #expect(service.lastCreatedMaxUses == 5)
    }

    @Test("Sem prazo não manda data de validade")
    func testNeverExpiringInvite() async {
        let service = TestMockInviteService()
        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        viewModel.validity = .never

        _ = await viewModel.create(createdBy: UUID())

        #expect(service.lastCreatedExpiry == nil)
    }

    @Test("Os três prazos são o que dizem ser")
    func testValidityMapping() {
        #expect(InviteManagementViewModel.Validity.never.expiryDate == nil)

        let week = InviteManagementViewModel.Validity.week.expiryDate ?? Date()
        let month = InviteManagementViewModel.Validity.month.expiryDate ?? Date()

        #expect(week > Date())
        #expect(week < month)
    }

    @Test("Prazo de sete dias cai no futuro")
    func testWeekValidity() async {
        let service = TestMockInviteService()
        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        viewModel.validity = .week

        _ = await viewModel.create(createdBy: UUID())

        let expiry = try? #require(service.lastCreatedExpiry)
        #expect((expiry ?? Date.distantPast) > Date())
    }

    @Test("O convite criado entra no topo da lista")
    func testCreatedInviteGoesFirst() async {
        let service = TestMockInviteService()
        service.invitesToReturn = [makeInvite(code: "AAAAAAAA")]

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        await viewModel.load()
        let created = await viewModel.create(createdBy: UUID())

        #expect(created != nil)
        #expect(viewModel.invites.count == 2)
        #expect(viewModel.invites.first?.id == created?.id)
    }

    @Test("Criação recusada não inventa convite na lista")
    func testCreateFailure() async {
        let service = TestMockInviteService()
        service.shouldThrowError = true

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        let created = await viewModel.create(createdBy: UUID())

        #expect(created == nil)
        #expect(viewModel.invites.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isCreating == false)
    }

    /// Revogação é otimista: marca na hora e desfaz se o servidor recusar. Sem o
    /// desfazer, a tela diria que o código está morto enquanto ele segue vivo.
    @Test("Revogar marca na hora")
    func testRevokeIsOptimistic() async {
        let service = TestMockInviteService()
        let invite = makeInvite()
        service.invitesToReturn = [invite]

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        await viewModel.load()
        await viewModel.revoke(invite)

        #expect(viewModel.invites.first?.isRevoked == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Revogação recusada volta atrás")
    func testRevokeRevertsOnFailure() async {
        let service = TestMockInviteService()
        let invite = makeInvite()
        service.invitesToReturn = [invite]

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: service)
        await viewModel.load()

        service.shouldThrowError = true
        await viewModel.revoke(invite)

        #expect(viewModel.invites.first?.isRevoked == false)
        #expect(viewModel.errorMessage != nil)
    }

    /// O código vem antes do link de propósito: o link só funciona em quem já tem o
    /// app, o código digitado funciona sempre.
    @Test("O texto de compartilhar traz o código antes do link")
    func testShareTextPutsTheCodeFirst() {
        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: TestMockInviteService())
        let invite = makeInvite(code: "4K7QX2MN")

        let text = viewModel.shareText(for: invite, chapterName: "Capítulo Alfa")

        let codePosition = try? #require(text.range(of: "4K7Q-X2MN")?.lowerBound)
        let linkPosition = text.range(of: "baluarte://invite/")?.lowerBound

        #expect(text.contains("Capítulo Alfa"))
        if let codePosition, let linkPosition {
            #expect(codePosition < linkPosition)
        }
    }
}
