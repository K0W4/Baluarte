import Testing
import Foundation
@testable import Baluarte

/// O que os modelos decidem sozinhos. São poucas regras, mas três delas sustentam
/// distinções que o resto do app assume: cargo não é permissão, nível de acesso tem
/// ordem, e o que atravessa o app group tem de sobreviver à ida e à volta.
@Suite("Regras que vivem nos modelos")
struct ModelLogicTests {

    // MARK: - AccessLevel

    /// A ordem é o que faz `>= .admin` significar alguma coisa em `PermissionSet`.
    @Test("Os três níveis têm ordem, e ela é essa")
    func testAccessLevelOrdering() {
        #expect(AccessLevel.member < AccessLevel.admin)
        #expect(AccessLevel.admin < AccessLevel.owner)
        #expect(AccessLevel.owner > AccessLevel.member)
        #expect(AccessLevel.allCases.count == 3)
    }

    /// O servidor pode devolver um nível que este app não conhece, e cair em `member`
    /// é a única queda segura: qualquer outra concederia acesso por acidente.
    @Test("Nível desconhecido cai em membro, nunca para cima")
    func testUnknownAccessLevelFallsToMember() {
        #expect(AccessLevel(rawValueOrMember: nil) == .member)
        #expect(AccessLevel(rawValueOrMember: "") == .member)
        #expect(AccessLevel(rawValueOrMember: "superadmin") == .member)
        #expect(AccessLevel(rawValueOrMember: "OWNER") == .owner)
        #expect(AccessLevel(rawValueOrMember: "admin") == .admin)
    }

    // MARK: - ChapterRole

    /// Cargo é descritivo e muda a cada gestão; permissão é `AccessLevel`. O que a
    /// lista de cargos faz é oferecer o que faz sentido para aquela categoria.
    @Test("A lista de cargos cresce com a categoria")
    func testRolesByCategory() {
        let active = ChapterRole.roles(isSenior: false, isMason: false)
        let senior = ChapterRole.roles(isSenior: true, isMason: false)
        let mason = ChapterRole.roles(isSenior: false, isMason: true)

        #expect(active.contains(ChapterRole.member))
        #expect(senior == ChapterRole.seniorRoles)
        #expect(mason == ChapterRole.masonRoles)
        #expect(active.count > senior.count)
    }

    /// A sugestão de administrador na aprovação sai desta lista. Ela é sugestão: quem
    /// aprova escolhe, e o servidor nunca lê o cargo para decidir acesso.
    @Test("Os cargos de oficial são os que sugerem administrador")
    func testOfficerRoles() {
        #expect(ChapterRole.officerRoles.contains("Mestre Conselheiro"))
        #expect(ChapterRole.officerRoles.contains("Escrivão"))
        #expect(ChapterRole.officerRoles.contains(ChapterRole.member) == false)
    }

    @Test("Um cargo desconhecido é mostrado como veio")
    func testUnknownRoleIsShownVerbatim() {
        #expect(ChapterRole.displayName(for: "Cargo Inventado") == "Cargo Inventado")
    }

    // MARK: - WidgetChapter

    /// É o contrato entre dois processos: o app escreve no app group e o widget lê. Uma
    /// mudança silenciosa de formato aqui deixa o seletor de Capítulo vazio sem
    /// derrubar nada, que é o pior tipo de falha.
    @Test("O que atravessa o app group sobrevive à ida e à volta")
    func testWidgetChapterRoundTrip() throws {
        let original = WidgetChapter(
            membershipId: UUID(), chapterId: UUID(), name: "Capítulo Alfa"
        )

        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([WidgetChapter].self, from: data)

        #expect(decoded == [original])
        #expect(decoded.first?.id == original.membershipId)
    }

    /// O id é o do vínculo, não o do Capítulo. Trocar um pelo outro mostraria o
    /// Capítulo certo com as tarefas de ninguém.
    @Test("A identidade de um WidgetChapter é o vínculo")
    func testWidgetChapterIdentityIsTheMembership() {
        let chapterId = UUID()
        let first = WidgetChapter(membershipId: UUID(), chapterId: chapterId, name: "Alfa")
        let second = WidgetChapter(membershipId: UUID(), chapterId: chapterId, name: "Alfa")

        #expect(first.id != second.id)
        #expect(first != second)
    }

    // MARK: - Member

    @Test("O roster projeta o nível de acesso a partir do texto")
    func testMemberLevelProjection() {
        func member(accessLevel: String) -> Member {
            Member(
                id: UUID(), fullName: "Alguém", isActive: true, isSenior: false,
                isMason: false, accessLevel: accessLevel, createdAt: Date()
            )
        }

        #expect(member(accessLevel: "owner").level == .owner)
        #expect(member(accessLevel: "admin").level == .admin)
        #expect(member(accessLevel: "qualquer coisa").level == .member)
    }

    // MARK: - ChapterInvite

    /// Vencido, esgotado e revogado são três formas de estar morto, e o resgate recusa
    /// as três com a mesma mensagem — distinguir contaria a um atacante quais códigos
    /// são reais.
    @Test("As três formas de um convite estar morto")
    func testInviteUsability() {
        func invite(expiresAt: Date? = nil, maxUses: Int? = nil, usesCount: Int = 0, revokedAt: Date? = nil) -> ChapterInvite {
            ChapterInvite(
                id: UUID(), chapterId: UUID(), code: "4K7QX2MN",
                expiresAt: expiresAt, maxUses: maxUses, usesCount: usesCount,
                revokedAt: revokedAt, createdBy: UUID(), createdAt: Date()
            )
        }

        #expect(invite().isUsable)
        #expect(invite(expiresAt: Date(timeIntervalSince1970: 0)).isUsable == false)
        #expect(invite(maxUses: 2, usesCount: 2).isUsable == false)
        #expect(invite(maxUses: 2, usesCount: 1).isUsable)
        #expect(invite(revokedAt: Date()).isUsable == false)
    }
}
