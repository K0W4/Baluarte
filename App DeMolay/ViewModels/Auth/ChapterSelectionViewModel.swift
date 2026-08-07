import Foundation

@Observable
public final class ChapterSelectionViewModel {
    public var chapters: [Chapter] = []
    public var isLoading = false
    public var errorMessage: String?
    public var selectedUF: BrazilianState?

    private let chapterService: ChapterServiceProtocol

    public init(chapterService: ChapterServiceProtocol = Services.chapter) {
        self.chapterService = chapterService
    }

    @MainActor
    public func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        self.isLoading = true
        self.errorMessage = nil
        do {
            self.chapters = try await chapterService.searchChapters(
                query: trimmed.isEmpty ? nil : trimmed,
                uf: selectedUF?.rawValue
            )
        } catch {
            if error is CancellationError { self.isLoading = false; return }
            self.errorMessage = AppError.from(error).userMessage
        }
        self.isLoading = false
    }
}
