import Foundation
@testable import Baluarte

public final class TestMockAuditService: AuditServiceProtocol {
    public var shouldThrowError = false

    /// Páginas em ordem: cada chamada consome a próxima. Sem isso não dá para provar a
    /// paginação, que é onde mora o cursor por id.
    public var pages: [[AccessChangeEntry]] = []

    public private(set) var chapterLogCallCount = 0
    public private(set) var platformLogCallCount = 0
    public private(set) var requestedBeforeIds: [Int?] = []
    public private(set) var lastChapterId: UUID?

    public init() {}

    private func nextPage() throws -> [AccessChangeEntry] {
        if shouldThrowError {
            throw NSError(
                domain: "TestMockAuditService", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to read the access log"]
            )
        }
        return pages.isEmpty ? [] : pages.removeFirst()
    }

    public func chapterAccessLog(chapterId: UUID, limit: Int, beforeId: Int?) async throws -> [AccessChangeEntry] {
        chapterLogCallCount += 1
        lastChapterId = chapterId
        requestedBeforeIds.append(beforeId)
        return try nextPage()
    }

    public func platformAccessLog(limit: Int, beforeId: Int?) async throws -> [AccessChangeEntry] {
        platformLogCallCount += 1
        requestedBeforeIds.append(beforeId)
        return try nextPage()
    }
}
