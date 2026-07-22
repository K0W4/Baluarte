import Foundation

public protocol MemberServiceProtocol {
    func fetchMembers(for chapterId: UUID) async throws -> [Member]
}
