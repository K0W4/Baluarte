import Foundation
@testable import Baluarte

public final class TestMockChapterService: ChapterServiceProtocol {
    public var shouldThrowError = false
    public var chaptersToReturn: [Chapter] = []
    public var chapterToReturn: Chapter?
    public var pendingRequestsToReturn: [PendingChapterRequest] = []

    public private(set) var reviewedRequests: [(id: UUID, approved: Bool, reason: String?)] = []

    public init() {}

    private func failIfNeeded(_ code: Int) throws {
        if shouldThrowError {
            throw NSError(domain: "TestMockChapterService", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Chapter service failure"])
        }
    }

    public func searchChapters(query: String?, uf: String?) async throws -> [Chapter] {
        try failIfNeeded(1)
        return chaptersToReturn
    }

    public func fetchChapter(id: UUID) async throws -> Chapter? {
        try failIfNeeded(2)
        return chapterToReturn
    }

    public func requestChapter(_ request: ChapterRequest) async throws {
        try failIfNeeded(3)
    }

    public func pendingChapterRequests() async throws -> [PendingChapterRequest] {
        try failIfNeeded(4)
        return pendingRequestsToReturn
    }

    public func reviewChapterRequest(id: UUID, approved: Bool, reason: String?) async throws {
        try failIfNeeded(5)
        reviewedRequests.append((id: id, approved: approved, reason: reason))
    }
}
