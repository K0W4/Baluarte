import Foundation

@Observable
@MainActor
public final class BootstrapQueueViewModel {
    public var requests: [BootstrapRequest] = []
    public var isLoading = false
    public var errorMessage: String?

    private let joinRequestService: JoinRequestServiceProtocol

    public init(joinRequestService: JoinRequestServiceProtocol = Services.joinRequest) {
        self.joinRequestService = joinRequestService
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            requests = try await joinRequestService.fetchPendingBootstrapRequests()
        } catch {
            if error is CancellationError { isLoading = false; return }
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    /// URL assinada e de vida curta: o bucket é privado, então o comprovante nunca fica
    /// acessível por link solto.
    public func proofURL(for request: BootstrapRequest) async -> URL? {
        guard let path = request.proofPath else { return nil }
        do {
            return try await joinRequestService.signedProofURL(path: path)
        } catch {
            errorMessage = AppError.from(error).userMessage
            return nil
        }
    }

    public func approve(_ request: BootstrapRequest) async -> Bool {
        errorMessage = nil
        do {
            // O nível é decidido pelo servidor para bootstrap: sempre Fundador.
            try await joinRequestService.approve(
                requestId: request.id,
                accessLevel: .owner,
                category: .ativo,
                role: nil,
                linkMembershipId: nil
            )
            requests.removeAll { $0.id == request.id }
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }

    public func reject(_ request: BootstrapRequest, reason: String?) async -> Bool {
        errorMessage = nil
        do {
            let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines)
            try await joinRequestService.reject(
                requestId: request.id,
                reason: (trimmed?.isEmpty ?? true) ? nil : trimmed
            )
            requests.removeAll { $0.id == request.id }
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }
}
