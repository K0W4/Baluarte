import Foundation

@Observable
@MainActor
public final class RequestChapterViewModel {
    public var name: String = ""
    public var number: String = ""
    public var city: String = ""
    public var uf: BrazilianState = .rs
    public var note: String = ""

    public var isLoading = false
    public var errorMessage: String?

    private let chapterService: ChapterServiceProtocol

    public init(chapterService: ChapterServiceProtocol = Services.chapter) {
        self.chapterService = chapterService
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isValid: Bool {
        !trimmedName.isEmpty && Int(number) != nil && !isLoading
    }

    public func submit(requestedBy: UUID) async -> Bool {
        guard isValid, let parsedNumber = Int(number) else { return false }

        isLoading = true
        errorMessage = nil

        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let request = ChapterRequest(
            requestedBy: requestedBy,
            name: trimmedName,
            number: parsedNumber,
            uf: uf.rawValue,
            city: trimmedCity.isEmpty ? nil : trimmedCity,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )

        do {
            try await chapterService.requestChapter(request)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { isLoading = false; return false }
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }
}
