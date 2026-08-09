import Foundation
@testable import Baluarte

/// Registra o que o `AuthViewModel` teria escrito no app group e no Keychain, sem
/// tocar nenhum dos dois.
public final class TestMockSessionStore: SessionStoreProtocol, @unchecked Sendable {
    public struct Saved: Equatable {
        public let userId: UUID?
        public let chapterId: UUID?
        public let membershipId: UUID?
        public let accessToken: String
        public let refreshToken: String
    }

    public private(set) var saves: [Saved] = []
    public private(set) var clearCount = 0

    public init() {}

    public func save(
        userId: UUID?, chapterId: UUID?, membershipId: UUID?,
        accessToken: String, refreshToken: String
    ) {
        saves.append(Saved(userId: userId, chapterId: chapterId, membershipId: membershipId,
                           accessToken: accessToken, refreshToken: refreshToken))
    }

    public func clear() { clearCount += 1 }
}
