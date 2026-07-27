import Foundation

public protocol ChapterServiceProtocol {
    func fetchChapters() async throws -> [Chapter]
    func searchChapters(query: String) async throws -> [Chapter]
    func createChapter(_ chapter: Chapter) async throws -> Chapter
}
