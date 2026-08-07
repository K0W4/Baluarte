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

    private let joinRequestService: JoinRequestServiceProtocol
    private let chapterId: UUID

    public static let memberRoles = [
        "Membro", "Mestre Conselheiro", "1º Conselheiro", "2º Conselheiro",
        "Escrivão", "Tesoureiro", "Hospitalário"
    ]

    /// Roles that normally run the chapter. Used only to *suggest* an access level —
    /// a cargo lasts a semester and must never grant permission by itself.
    private static let rolesSuggestingAdmin: Set<String> = [
        "Mestre Conselheiro", "1º Conselheiro", "2º Conselheiro", "Escrivão", "Consultor"
    ]

    public var suggestsAdmin: Bool {
        Self.rolesSuggestingAdmin.contains(role)
    }

    public init(chapterId: UUID, joinRequestService: JoinRequestServiceProtocol = Services.joinRequest) {
        self.chapterId = chapterId
        self.joinRequestService = joinRequestService
    }

    public func applyRoleSuggestion() {
        accessLevel = suggestsAdmin ? .admin : .member
    }

    public func resetForm() {
        role = "Membro"
        category = .ativo
        accessLevel = .member
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            requests = try await joinRequestService.fetchPendingRequests(for: chapterId)
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
                role: role == "Membro" ? nil : role
            )
            requests.removeAll { $0.id == pending.id }
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
