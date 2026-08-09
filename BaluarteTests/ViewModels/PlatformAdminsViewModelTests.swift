import Testing
import Foundation
@testable import Baluarte

/// Cadeia de confiança: só quem já administra a plataforma concede a outro. A tela não
/// decide isso — `set_platform_admin` decide, e recusa quem não tem o status. O que
/// estes testes cobrem é o que a tela faz com a resposta.
@MainActor
@Suite("PlatformAdminsViewModel Tests")
struct PlatformAdminsViewModelTests {

    private func makeAdmin(name: String = "Quem administra") -> PlatformAdmin {
        PlatformAdmin(id: UUID(), fullName: name, email: "admin@baluarte.app")
    }

    @Test("load traz a lista de pares")
    func testLoad() async {
        let service = TestMockMembershipService()
        service.platformAdminsResult = [makeAdmin(), makeAdmin(name: "Outro")]

        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: service)
        await viewModel.load()

        #expect(viewModel.admins.count == 2)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("Falha ao listar aparece na tela")
    func testLoadFailure() async {
        let service = TestMockMembershipService()
        service.shouldThrowError = true

        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: service)
        await viewModel.load()

        #expect(viewModel.admins.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    /// A concessão é por CID e não por busca de pessoas: uma tela que listasse todo
    /// mundo do app seria uma lista de gente que quem administra não tem motivo para
    /// ver. O CID vem da própria pessoa, fora do app — isso é parte da cadeia.
    @Test("CID em branco não vale")
    func testCIDValidation() {
        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: TestMockMembershipService())

        #expect(viewModel.isValidCID == false)

        viewModel.cidToGrant = "   "
        #expect(viewModel.isValidCID == false)

        viewModel.cidToGrant = " 5820 "
        #expect(viewModel.isValidCID)
    }

    @Test("Conceder envia o CID sem espaços e limpa o campo")
    func testGrantTrimsAndClears() async {
        let service = TestMockMembershipService()
        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: service)
        viewModel.cidToGrant = "  5820  "

        #expect(await viewModel.grant())

        #expect(service.grantedCIDs == ["5820"])
        #expect(viewModel.cidToGrant.isEmpty)
    }

    @Test("CID vazio nem chega ao servidor")
    func testGrantWithoutCID() async {
        let service = TestMockMembershipService()
        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: service)
        viewModel.cidToGrant = "  "

        #expect(await viewModel.grant() == false)
        #expect(service.grantedCIDs.isEmpty)
    }

    @Test("Concessão recusada mantém o que foi digitado")
    func testGrantFailureKeepsTheInput() async {
        let service = TestMockMembershipService()
        service.shouldThrowError = true

        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: service)
        viewModel.cidToGrant = "5820"

        #expect(await viewModel.grant() == false)
        #expect(viewModel.cidToGrant == "5820")
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("Revogar recarrega a lista")
    func testRevokeReloads() async {
        let service = TestMockMembershipService()
        let admin = makeAdmin()
        service.platformAdminsResult = [admin]

        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: service)
        await viewModel.load()

        service.platformAdminsResult = []
        #expect(await viewModel.revoke(admin))

        #expect(service.revokedMemberIds == [admin.id])
        #expect(viewModel.admins.isEmpty)
    }

    /// O último administrador de plataforma não pode se remover — sem ninguém, nenhuma
    /// fundação de Capítulo é aprovada nunca mais. A recusa é do servidor; aqui só se
    /// prova que a mensagem chega.
    @Test("Revogação recusada explica em vez de sumir")
    func testRevokeFailureSurfaces() async {
        let service = TestMockMembershipService()
        let admin = makeAdmin()
        service.platformAdminsResult = [admin]

        let viewModel = PlatformAdminsViewModel(currentUserId: UUID(), membershipService: service)
        await viewModel.load()

        service.shouldThrowError = true
        #expect(await viewModel.revoke(admin) == false)

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("A própria linha é reconhecida")
    func testIsSelf() {
        let me = UUID()
        let mine = PlatformAdmin(id: me, fullName: "Eu", email: nil)
        let other = makeAdmin()

        let viewModel = PlatformAdminsViewModel(currentUserId: me, membershipService: TestMockMembershipService())

        #expect(viewModel.isSelf(mine))
        #expect(viewModel.isSelf(other) == false)
    }
}
