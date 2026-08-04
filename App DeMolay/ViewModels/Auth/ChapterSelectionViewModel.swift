import Foundation

@Observable
public final class ChapterSelectionViewModel {
    public var chapters: [Chapter] = []
    public var isLoading = false
    public var errorMessage: String?
    
    private let chapterService: ChapterServiceProtocol
    private let memberService: MemberServiceProtocol
    
    public init(chapterService: ChapterServiceProtocol = Services.chapter, memberService: MemberServiceProtocol = Services.member) {
        self.chapterService = chapterService
        self.memberService = memberService
    }
    
    @MainActor
    public func fetchChapters() async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            self.chapters = try await chapterService.fetchChapters()
        } catch {
            self.errorMessage = AppError.from(error).userMessage
        }
        self.isLoading = false
    }
    
    @MainActor
    public func searchChapters(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await fetchChapters()
            return
        }

        self.isLoading = true
        self.errorMessage = nil
        do {
            self.chapters = try await chapterService.searchChapters(query: trimmed)
        } catch {
            if error is CancellationError { self.isLoading = false; return }
            self.errorMessage = AppError.from(error).userMessage
        }
        self.isLoading = false
    }

    @MainActor
    public func selectChapter(_ chapter: Chapter, for member: Member) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        do {
            var updatedMember = member
            updatedMember.chapterId = chapter.id
            try await memberService.updateMember(updatedMember)
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.isLoading = false
            return false
        }
    }
}
