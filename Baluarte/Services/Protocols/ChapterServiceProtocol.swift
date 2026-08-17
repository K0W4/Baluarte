import Foundation

/// The chapter registry is curated reference data: readable by anyone, writable by
/// nobody through the app. A chapter that is missing is requested, not created.
public protocol ChapterServiceProtocol {
    func searchChapters(query: String?, uf: String?) async throws -> [Chapter]
    func fetchChapter(id: UUID) async throws -> Chapter?
    func requestChapter(_ request: ChapterRequest) async throws

    /// A fila de quem pediu um Capítulo que não está no catálogo. Só quem revisa
    /// enxerga: a RPC filtra por `is_platform_admin()` no servidor.
    func pendingChapterRequests() async throws -> [PendingChapterRequest]
    func reviewChapterRequest(id: UUID, approved: Bool, reason: String?) async throws
}
