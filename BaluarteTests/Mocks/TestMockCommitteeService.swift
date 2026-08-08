import Foundation
@testable import Baluarte

public final class TestMockCommitteeService: CommitteeServiceProtocol {
    public var shouldThrowError = false
    public var committeesToReturn: [Committee] = []
    
    public var fetchCommitteesCallCount = 0
    public var createCommitteeCallCount = 0
    public var updateCommitteeCallCount = 0
    public var deleteCommitteeCallCount = 0
    
    public init() {}
    
    public func fetchCommittees(for chapterId: UUID) async throws -> [Committee] {
        fetchCommitteesCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockCommitteeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch committees"])
        }
        return committeesToReturn
    }
    
    public func createCommittee(_ committee: Committee) async throws {
        createCommitteeCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockCommitteeService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create committee"])
        }
    }
    
    public func updateCommittee(_ committee: Committee) async throws {
        updateCommitteeCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockCommitteeService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to update committee"])
        }
    }
    
    public func deleteCommittee(committeeId: UUID) async throws {
        deleteCommitteeCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockCommitteeService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to delete committee"])
        }
    }
}
