import Foundation

/// The chapter registry is curated reference data: readable by anyone, writable by
/// nobody through the app. A chapter that is missing is requested, not created.
public protocol ChapterServiceProtocol {
    func searchChapters(query: String?, uf: String?) async throws -> [Chapter]
    func requestChapter(_ request: ChapterRequest) async throws
}
