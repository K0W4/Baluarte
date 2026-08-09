import Foundation

/// Quem aparece numa ponta do registro. As três possibilidades são diferentes e
/// confundi-las seria mentir: sem ator é o sistema; ator com id e sem nome é uma conta
/// que foi excluída depois -- o nome saiu com ela, que é o que
/// `anonymize_on_account_deletion` garante.
public enum AccessLogParty: Hashable, Sendable {
    case person(String)
    case removedAccount
    case system
}

/// O que aconteceu, já interpretado. A tabela guarda `old_value` e `new_value` porque
/// o gatilho não deve narrar; a leitura é que decide se aquilo foi promoção,
/// rebaixamento ou transferência.
public enum AccessLogEvent: Hashable, Sendable {
    case joinedWith(AccessLevel)
    case promoted(to: AccessLevel)
    case demoted(to: AccessLevel)
    case ownershipTransferred
    case accessClearedOnAccountDeletion
    case platformAdminGranted
    case platformAdminRevoked
    case inviteRevoked
    case inviteDeleted
    case unknown
}

public struct AccessLogRow: Identifiable, Hashable, Sendable {
    public let id: Int
    public let occurredAt: Date
    public let event: AccessLogEvent
    public let actor: AccessLogParty
    public let subject: AccessLogParty?

    public init(
        id: Int,
        occurredAt: Date,
        event: AccessLogEvent,
        actor: AccessLogParty,
        subject: AccessLogParty?
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.event = event
        self.actor = actor
        self.subject = subject
    }
}
