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
            if try await chapterService.chapterExists(number: number) {
                throw AppError.validationFailed("Já existe um Capítulo com o número \(number). Verifique se o seu já está cadastrado antes de criar outro.")
            }

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
            self.errorMessage = AppError.from(error).userMessage
            self.isLoading = false
            throw error
        }
    }
}
