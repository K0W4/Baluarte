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
        guard !query.isEmpty else {
            await fetchChapters()
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        do {
            self.chapters = try await chapterService.searchChapters(query: query)
        } catch {
            self.errorMessage = AppError.from(error).userMessage
        }
        self.isLoading = false
    }
    
    @MainActor
    public func selectChapter(_ chapter: Chapter, for member: Member) async throws -> Member {
        self.isLoading = true
        do {
            var updatedMember = member
            updatedMember.chapterId = chapter.id
            try await memberService.updateMember(updatedMember)
            self.isLoading = false
            return updatedMember
        } catch {
            self.isLoading = false
            throw error
        }
    }
}
