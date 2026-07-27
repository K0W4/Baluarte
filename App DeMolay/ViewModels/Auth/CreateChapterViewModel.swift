import Foundation

@Observable
public final class CreateChapterViewModel {
    public var isLoading = false
    public var errorMessage: String?
    
    private let chapterService: ChapterServiceProtocol
    
    public init(chapterService: ChapterServiceProtocol = Services.chapter) {
        self.chapterService = chapterService
    }
    
    @MainActor
    public func createChapter(name: String, number: Int) async throws -> Chapter {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let newChapter = Chapter(
                id: UUID(),
                name: name,
                number: number,
                currentTermStart: nil,
                currentTermEnd: nil,
                createdAt: nil
            )
            let insertedChapter = try await chapterService.createChapter(newChapter)
            self.isLoading = false
            return insertedChapter
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            throw error
        }
    }
}
