import Foundation

public protocol CommitteeServiceProtocol {
    func fetchCommittees(for chapterId: UUID) async throws -> [Committee]
}
