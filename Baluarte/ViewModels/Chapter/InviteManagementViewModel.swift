import Foundation

@Observable
@MainActor
public final class InviteManagementViewModel {
    public enum Validity: String, CaseIterable, Identifiable {
        case week = "7 dias"
        case month = "30 dias"
        case never = "Sem prazo"

        public var id: String { rawValue }

        public var expiryDate: Date? {
            switch self {
            case .week: return Calendar.current.date(byAdding: .day, value: 7, to: Date())
            case .month: return Calendar.current.date(byAdding: .day, value: 30, to: Date())
            case .never: return nil
            }
        }
    }

    public var invites: [ChapterInvite] = []
    public var isLoading = false
    public var isCreating = false
    public var errorMessage: String?

    public var validity: Validity = .week
    public var limitUses = false
    public var maxUses: Int = 30

    private let inviteService: InviteServiceProtocol
    private let chapterId: UUID

    public init(chapterId: UUID, inviteService: InviteServiceProtocol = Services.invite) {
        self.chapterId = chapterId
        self.inviteService = inviteService
    }

    public var activeInvites: [ChapterInvite] { invites.filter { $0.isUsable } }
    public var inactiveInvites: [ChapterInvite] { invites.filter { !$0.isUsable } }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            invites = try await inviteService.fetchInvites(for: chapterId)
        } catch {
            if error is CancellationError { isLoading = false; return }
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    public func create(createdBy: UUID) async -> ChapterInvite? {
        isCreating = true
        errorMessage = nil
        do {
            let invite = try await inviteService.createInvite(
                chapterId: chapterId,
                createdBy: createdBy,
                expiresAt: validity.expiryDate,
                maxUses: limitUses ? maxUses : nil
            )
            invites.insert(invite, at: 0)
            isCreating = false
            return invite
        } catch {
            errorMessage = AppError.from(error).userMessage
            isCreating = false
            return nil
        }
    }

    public func revoke(_ invite: ChapterInvite) async {
        errorMessage = nil
        let snapshot = invites
        if let index = invites.firstIndex(where: { $0.id == invite.id }) {
            invites[index].revokedAt = Date()
        }

        do {
            try await inviteService.revokeInvite(id: invite.id)
        } catch {
            invites = snapshot
            errorMessage = AppError.from(error).userMessage
        }
    }

    /// O código vem primeiro e o link depois: o link só funciona em quem já tem o app
    /// instalado, o código digitado funciona sempre.
    public func shareText(for invite: ChapterInvite, chapterName: String) -> String {
        var text = """
        Entre no \(chapterName) pelo Baluarte.

        Código: \(invite.formattedCode)

        No app, toque em “Tenho um código de convite” e digite o código acima.
        """

        if let url = DeepLink.inviteURL(code: invite.code) {
            text += "\n\nCom o app instalado, este link abre direto: \(url.absoluteString)"
        }

        return text
    }
}
