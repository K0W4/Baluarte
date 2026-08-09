import Testing
import Foundation
@testable import Baluarte

@Suite("AccessChangeEntry Tests")
struct AccessChangeEntryTests {

    private func decode(_ json: String) throws -> AccessChangeEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AccessChangeEntry.self, from: Data(json.utf8))
    }

    @Test("Decodes a row from chapter_access_log")
    func testDecodesChapterRow() throws {
        let json = """
        {
          "id": 42,
          "txid": 998877,
          "occurred_at": "2026-08-09T18:30:00Z",
          "action": "access_level_changed",
          "actor_id": "11111111-1111-1111-1111-111111111111",
          "actor_name": "Fundador",
          "subject_membership_id": "22222222-2222-2222-2222-222222222222",
          "subject_name": "João da Silva",
          "old_value": "member",
          "new_value": "admin"
        }
        """

        let entry = try decode(json)

        #expect(entry.id == 42)
        #expect(entry.txid == 998877)
        #expect(entry.action == .accessLevelChanged)
        #expect(entry.actorName == "Fundador")
        #expect(entry.subjectName == "João da Silva")
        #expect(entry.oldLevel == .member)
        #expect(entry.newLevel == .admin)
        #expect(entry.subjectMemberId == nil)
    }

    /// A função de plataforma devolve `subject_member_id` no lugar de
    /// `subject_membership_id`. As duas colunas convivem no mesmo modelo, então a que
    /// falta tem de virar nulo em vez de derrubar a decodificação.
    @Test("Decodes a row from platform_access_log")
    func testDecodesPlatformRow() throws {
        let json = """
        {
          "id": 7,
          "txid": 1,
          "occurred_at": "2026-08-09T18:30:00Z",
          "action": "platform_admin_changed",
          "actor_id": "11111111-1111-1111-1111-111111111111",
          "actor_name": "Quem concedeu",
          "subject_member_id": "33333333-3333-3333-3333-333333333333",
          "subject_name": "Quem recebeu",
          "old_value": "false",
          "new_value": "true"
        }
        """

        let entry = try decode(json)

        #expect(entry.action == .platformAdminChanged)
        #expect(entry.subjectMembershipId == nil)
        #expect(entry.subjectMemberId != nil)
        #expect(entry.newLevel == nil)
    }

    @Test("A missing actor decodes as absent, not as a failure")
    func testDecodesSystemActor() throws {
        let json = """
        {
          "id": 3,
          "txid": 5,
          "occurred_at": "2026-08-09T18:30:00Z",
          "action": "access_cleared_on_account_deletion",
          "actor_id": null,
          "actor_name": null,
          "subject_membership_id": "22222222-2222-2222-2222-222222222222",
          "subject_name": "Membro removido",
          "old_value": "admin",
          "new_value": "member"
        }
        """

        let entry = try decode(json)

        #expect(entry.actorId == nil)
        #expect(entry.actorName == nil)
        #expect(entry.action == .accessClearedOnAccountDeletion)
    }

    /// Uma ação que este app não conhece vem de um banco mais novo. Ela tem de virar
    /// `unknown`, e não derrubar a lista inteira -- a tela ficaria vazia justamente
    /// para quem foi conferir alguma coisa.
    @Test("An unknown action does not take the list down with it")
    func testUnknownActionFallsBack() throws {
        let json = """
        {
          "id": 1,
          "txid": 1,
          "occurred_at": "2026-08-09T18:30:00Z",
          "action": "something_a_later_migration_added",
          "actor_id": null,
          "actor_name": null,
          "old_value": null,
          "new_value": null
        }
        """

        let entry = try decode(json)

        #expect(entry.action == .unknown)
    }
}
