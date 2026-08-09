import Foundation
import Observation

/// O log de um Capítulo é do Fundador; o de plataforma, de quem administra a
/// plataforma. As duas restrições valem no servidor -- aqui a distinção só decide qual
/// função chamar.
public enum AccessLogScope: Hashable, Sendable {
    case chapter(UUID)
    case platform
}

@MainActor
@Observable
public final class AccessLogViewModel {
    public private(set) var entries: [AccessChangeEntry] = []
    public private(set) var hasMore = false
    public var isLoading = false
    public var errorMessage: String?

    private let scope: AccessLogScope
    private let auditService: AuditServiceProtocol
    private let pageSize: Int

    public init(
        scope: AccessLogScope,
        auditService: AuditServiceProtocol = Services.audit,
        pageSize: Int = 50
    ) {
        self.scope = scope
        self.auditService = auditService
        self.pageSize = pageSize
    }

    public var isEmpty: Bool { entries.isEmpty && !isLoading }

    /// As linhas cruas viram eventos aqui, e não no gatilho, porque só quem lê a
    /// sequência inteira consegue reconhecer uma transferência de posse: são duas
    /// mudanças de nível na mesma transação, uma saindo de Fundador e outra entrando.
    public var rows: [AccessLogRow] {
        Self.rows(from: entries)
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let page = try await fetch(beforeId: nil)
            entries = page
            hasMore = page.count >= pageSize
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    /// Pagina pelo id, e não pela hora: as duas linhas de uma transferência carregam o
    /// mesmo `now()`, e um cursor por tempo pularia uma delas.
    public func loadMore() async {
        guard hasMore, !isLoading, let lastId = entries.last?.id else { return }

        isLoading = true
        errorMessage = nil
        do {
            let page = try await fetch(beforeId: lastId)
            entries.append(contentsOf: page)
            hasMore = page.count >= pageSize
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    private func fetch(beforeId: Int?) async throws -> [AccessChangeEntry] {
        switch scope {
        case let .chapter(chapterId):
            return try await auditService.chapterAccessLog(
                chapterId: chapterId, limit: pageSize, beforeId: beforeId
            )
        case .platform:
            return try await auditService.platformAccessLog(
                limit: pageSize, beforeId: beforeId
            )
        }
    }

    // MARK: - Interpretação

    static func rows(from entries: [AccessChangeEntry]) -> [AccessLogRow] {
        var result: [AccessLogRow] = []
        var index = 0

        while index < entries.count {
            let entry = entries[index]
            let sameTransaction = entries[index...].prefix { $0.txid == entry.txid }

            if let transfer = transferRow(from: Array(sameTransaction)) {
                result.append(transfer)
                index += sameTransaction.count
                continue
            }

            result.append(row(from: entry))
            index += 1
        }

        return result
    }

    /// Uma transferência é o par: alguém deixa de ser Fundador e outra pessoa passa a
    /// ser, na mesma transação. Só o segundo lado interessa a quem lê -- o primeiro é
    /// consequência mecânica e apareceria como "rebaixamento do Fundador", que é
    /// exatamente a leitura errada.
    private static func transferRow(from group: [AccessChangeEntry]) -> AccessLogRow? {
        // Exatamente duas: é o que `transfer_chapter_ownership` escreve. Aceitar mais
        // engoliria uma terceira linha que só por acaso caiu na mesma transação.
        guard group.count == 2 else { return nil }

        guard let incoming = group.first(where: { $0.newLevel == .owner }),
              group.contains(where: { $0.oldLevel == .owner && $0.newLevel != .owner })
        else { return nil }

        let id = group.map(\.id).max() ?? incoming.id

        return AccessLogRow(
            id: id,
            occurredAt: incoming.occurredAt,
            event: .ownershipTransferred,
            actor: party(id: incoming.actorId, name: incoming.actorName),
            subject: subjectParty(incoming)
        )
    }

    private static func row(from entry: AccessChangeEntry) -> AccessLogRow {
        AccessLogRow(
            id: entry.id,
            occurredAt: entry.occurredAt,
            event: event(from: entry),
            actor: party(id: entry.actorId, name: entry.actorName),
            subject: subjectParty(entry)
        )
    }

    private static func event(from entry: AccessChangeEntry) -> AccessLogEvent {
        switch entry.action {
        case .accessLevelChanged:
            guard let newLevel = entry.newLevel else { return .unknown }
            guard let oldLevel = entry.oldLevel else { return .joinedWith(newLevel) }
            return newLevel > oldLevel ? .promoted(to: newLevel) : .demoted(to: newLevel)
        case .accessClearedOnAccountDeletion:
            return .accessClearedOnAccountDeletion
        case .platformAdminChanged:
            return entry.newValue == "true" ? .platformAdminGranted : .platformAdminRevoked
        case .inviteRevoked:
            return .inviteRevoked
        case .inviteDeleted:
            return .inviteDeleted
        case .unknown:
            return .unknown
        }
    }

    private static func party(id: UUID?, name: String?) -> AccessLogParty {
        if let name, !name.isEmpty { return .person(name) }
        return id == nil ? .system : .removedAccount
    }

    /// Convite não tem sujeito: quem foi retirado é o código, não uma pessoa.
    private static func subjectParty(_ entry: AccessChangeEntry) -> AccessLogParty? {
        switch entry.action {
        case .inviteRevoked, .inviteDeleted:
            return nil
        default:
            if let name = entry.subjectName, !name.isEmpty { return .person(name) }
            return .removedAccount
        }
    }
}
