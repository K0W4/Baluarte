import Foundation

@Observable
@MainActor
public final class JoinRequestsViewModel {
    public var requests: [PendingJoinRequest] = []
    public var isLoading = false
    public var errorMessage: String?

    /// The role picked in the approval sheet, mirroring the roster form's own list.
    public var role: String = "Membro"
    public var category: MembershipCategory = .ativo
    public var accessLevel: AccessLevel = .member

    /// Cadastros feitos à mão que ainda não pertencem a ninguém — os candidatos a
    /// serem reaproveitados em vez de duplicados.
    public var unclaimedEntries: [Member] = []
    public var linkedMembershipId: UUID?

    private let joinRequestService: JoinRequestServiceProtocol
    private let memberService: MemberServiceProtocol
    private let chapterId: UUID

    /// Os cargos vêm de `ChapterRole`, e não de uma cópia. As duas listas que existiam
    /// aqui duplicavam `activeRoles` e `officerRoles` — e como o `Picker` exibia o valor
    /// cru, o cargo aparecia em português para quem usa o app em inglês ou espanhol.
    /// `ChapterRole.displayName(for:)` é o que traduz; o valor gravado segue em português,
    /// que é a nomenclatura oficial da Ordem.
    public static let memberRoles = ChapterRole.activeRoles

    /// Cargos que normalmente administram o Capítulo. Serve só para *sugerir* um nível de
    /// acesso — cargo dura uma gestão e nunca concede permissão por si.
    public var suggestsAdmin: Bool {
        ChapterRole.officerRoles.contains(role)
    }

    public init(
        chapterId: UUID,
        joinRequestService: JoinRequestServiceProtocol = Services.joinRequest,
        memberService: MemberServiceProtocol = Services.member
    ) {
        self.chapterId = chapterId
        self.joinRequestService = joinRequestService
        self.memberService = memberService
    }

    /// Sugere o cadastro cujo nome bate com o de quem pediu. É só uma sugestão: a
    /// confirmação continua humana, porque homônimo existe.
    public func suggestedEntry(for pending: PendingJoinRequest) -> Member? {
        let normalized = pending.applicantName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return unclaimedEntries.first {
            $0.fullName
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                .trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }
    }

    public func applyRoleSuggestion() {
        accessLevel = suggestsAdmin ? .admin : .member
    }

    public func resetForm(for pending: PendingJoinRequest? = nil) {
        role = "Membro"
        category = .ativo
        accessLevel = .member
        linkedMembershipId = pending.flatMap { suggestedEntry(for: $0)?.id }
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let pending = joinRequestService.fetchPendingRequests(for: chapterId)
            async let roster = memberService.fetchMembers(for: chapterId)
            let (fetchedPending, fetchedRoster) = try await (pending, roster)
            requests = fetchedPending
            unclaimedEntries = fetchedRoster.filter { !$0.hasAccount }
        } catch {
            if error is CancellationError { isLoading = false; return }
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    public func approve(_ pending: PendingJoinRequest) async -> Bool {
        errorMessage = nil
        do {
            try await joinRequestService.approve(
                requestId: pending.id,
                accessLevel: accessLevel,
                category: category,
                role: role == "Membro" ? nil : role,
                linkMembershipId: linkedMembershipId
            )
            requests.removeAll { $0.id == pending.id }
            if let linkedMembershipId {
                unclaimedEntries.removeAll { $0.id == linkedMembershipId }
            }
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }

    public func reject(_ pending: PendingJoinRequest, reason: String?) async -> Bool {
        errorMessage = nil
        do {
            let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines)
            try await joinRequestService.reject(
                requestId: pending.id,
                reason: (trimmed?.isEmpty ?? true) ? nil : trimmed
            )
            requests.removeAll { $0.id == pending.id }
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }
}
