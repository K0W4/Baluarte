import Foundation

@Observable
@MainActor
public final class RedeemInviteViewModel {
    public var code: String = ""
    public var isLoading = false
    public var errorMessage: String?

    private let inviteService: InviteServiceProtocol

    public init(inviteService: InviteServiceProtocol = Services.invite) {
        self.inviteService = inviteService
    }

    public var isValid: Bool {
        InviteCode.isComplete(code) && !isLoading
    }

    /// Keeps the field readable while typing without ever letting the separator or a
    /// stray character reach the server.
    public func formatInput(_ raw: String) {
        let normalized = InviteCode.normalize(raw)
        let clamped = String(normalized.prefix(InviteCode.length))
        let formatted = InviteCode.format(clamped)
        if code != formatted { code = formatted }
    }

    public func redeem() async -> ChapterMembership? {
        guard isValid else { return nil }

        isLoading = true
        errorMessage = nil
        do {
            let membership = try await inviteService.redeem(code: code)
            isLoading = false
            return membership
        } catch {
            if error is CancellationError { isLoading = false; return nil }
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return nil
        }
    }
}
