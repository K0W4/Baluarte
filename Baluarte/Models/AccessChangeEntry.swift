import Foundation

/// Uma linha crua da auditoria, como `chapter_access_log` e `platform_access_log`
/// devolvem. O que ela significa para quem lê é decidido em `AccessLogViewModel`:
/// aqui não há interpretação, porque o servidor grava fato e não narrativa.
public struct AccessChangeEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: Int

    /// As duas linhas de uma transferência de posse compartilham o mesmo `txid`. É por
    /// ele que se reconhece o par -- e não pela hora, que é idêntica nas duas.
    public let txid: Int
    public let occurredAt: Date
    public let action: AccessChangeAction

    /// Nulo quando ninguém autenticado fez a mudança: script, painel ou a exclusão de
    /// conta. Um id presente com nome nulo é outra coisa -- a conta foi excluída
    /// depois, e o nome saiu junto com ela.
    public let actorId: UUID?
    public let actorName: String?

    public let subjectMembershipId: UUID?
    public let subjectMemberId: UUID?
    public let subjectName: String?

    public let oldValue: String?
    public let newValue: String?

    public init(
        id: Int,
        txid: Int,
        occurredAt: Date,
        action: AccessChangeAction,
        actorId: UUID? = nil,
        actorName: String? = nil,
        subjectMembershipId: UUID? = nil,
        subjectMemberId: UUID? = nil,
        subjectName: String? = nil,
        oldValue: String? = nil,
        newValue: String? = nil
    ) {
        self.id = id
        self.txid = txid
        self.occurredAt = occurredAt
        self.action = action
        self.actorId = actorId
        self.actorName = actorName
        self.subjectMembershipId = subjectMembershipId
        self.subjectMemberId = subjectMemberId
        self.subjectName = subjectName
        self.oldValue = oldValue
        self.newValue = newValue
    }

    public var oldLevel: AccessLevel? {
        oldValue.flatMap(AccessLevel.init(rawValue:))
    }

    public var newLevel: AccessLevel? {
        newValue.flatMap(AccessLevel.init(rawValue:))
    }

    enum CodingKeys: String, CodingKey {
        case id, txid, action
        case occurredAt = "occurred_at"
        case actorId = "actor_id"
        case actorName = "actor_name"
        case subjectMembershipId = "subject_membership_id"
        case subjectMemberId = "subject_member_id"
        case subjectName = "subject_name"
        case oldValue = "old_value"
        case newValue = "new_value"
    }
}

/// O `check` da tabela fixa este conjunto, mas uma versão nova do banco pode
/// acrescentar um caso. Sem o `unknown`, uma ação desconhecida derrubaria a
/// decodificação da lista inteira e a tela ficaria vazia em vez de incompleta.
public enum AccessChangeAction: String, Codable, Hashable, Sendable {
    case accessLevelChanged = "access_level_changed"
    case accessClearedOnAccountDeletion = "access_cleared_on_account_deletion"
    case platformAdminChanged = "platform_admin_changed"
    case inviteRevoked = "invite_revoked"
    case inviteDeleted = "invite_deleted"
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AccessChangeAction(rawValue: raw) ?? .unknown
    }
}
