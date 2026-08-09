import Foundation
import Observation

@MainActor
@Observable
public final class PlatformAdminsViewModel {
    public var admins: [PlatformAdmin] = []
    public var isLoading = false
    public var errorMessage: String?

    /// Concedido por CID, e não por busca de pessoas: uma tela que lista todo mundo
    /// do app para um administrador de plataforma escolher seria uma lista de
    /// pessoas que ele não tem motivo para ver. O CID ele recebe de quem vai receber
    /// o acesso — e essa troca fora do app é parte da cadeia de confiança.
    public var cidToGrant = ""

    private let membershipService: MembershipServiceProtocol
    private let currentUserId: UUID?

    public init(
        currentUserId: UUID?,
        membershipService: MembershipServiceProtocol = Services.membership
    ) {
        self.currentUserId = currentUserId
        self.membershipService = membershipService
    }

    public var isValidCID: Bool {
        !cidToGrant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func isSelf(_ admin: PlatformAdmin) -> Bool {
        admin.id == currentUserId
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            admins = try await membershipService.platformAdmins()
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    public func grant() async -> Bool {
        let cid = cidToGrant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return false }

        isLoading = true
        errorMessage = nil
        do {
            try await membershipService.grantPlatformAdmin(cid: cid)
            cidToGrant = ""
            await load()
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }

    public func revoke(_ admin: PlatformAdmin) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            try await membershipService.revokePlatformAdmin(memberId: admin.id)
            await load()
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }
}
