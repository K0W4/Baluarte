import Foundation
@testable import App_DeMolay

public final class TestMockMemberService: MemberServiceProtocol {
    public var shouldThrowError = false
    public var membersToReturn: [Member] = []
    
    public var fetchMembersCallCount = 0
    public var createMemberCallCount = 0
    public var updateMemberCallCount = 0
    public var deleteMemberCallCount = 0
    
    public init() {}
    
    public func fetchMembers(for chapterId: UUID) async throws -> [Member] {
        fetchMembersCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMemberService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch members"])
        }
        return membersToReturn
    }
    
    public func createMember(_ member: Member) async throws {
        createMemberCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMemberService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create member"])
        }
    }
    
    public func updateMember(_ member: Member) async throws {
        updateMemberCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMemberService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to update member"])
        }
    }
    
    public func deleteMember(memberId: UUID) async throws {
        deleteMemberCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "TestMockMemberService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to delete member"])
        }
    }
}
