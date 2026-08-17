import Foundation
import Observation

@MainActor
@Observable
public final class ChapterRequestsViewModel {
    public var requests: [PendingChapterRequest] = []
    public var isLoading = false
    public var errorMessage: String?

    private let chapterService: ChapterServiceProtocol

    public init(chapterService: ChapterServiceProtocol = Services.chapter) {
        self.chapterService = chapterService
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            requests = try await chapterService.pendingChapterRequests()
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    public func approve(_ request: PendingChapterRequest) async -> Bool {
        await review(request, approved: true, reason: nil)
    }

    public func reject(_ request: PendingChapterRequest, reason: String?) async -> Bool {
        await review(request, approved: false, reason: reason)
    }

    private func review(_ request: PendingChapterRequest, approved: Bool, reason: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            try await chapterService.reviewChapterRequest(
                id: request.id, approved: approved, reason: reason
            )
            // Recarrega em vez de remover da lista: outra pessoa da plataforma pode
            // ter revisado outro pedido enquanto esta tela estava aberta.
            await load()
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }
}
