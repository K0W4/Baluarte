import Foundation

public protocol CommitteeServiceProtocol {
    func fetchCommittees(for chapterId: UUID) async throws -> [Committee]
    func createCommittee(_ committee: Committee) async throws
    func updateCommittee(_ committee: Committee) async throws
    func deleteCommittee(committeeId: UUID) async throws
}
