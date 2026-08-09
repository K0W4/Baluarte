import Foundation
import Supabase
@testable import Baluarte

public final class TestMockAuthService: AuthServiceProtocol {
    public var shouldThrowError = false
    public var sessionToReturn: Session?

    public var signOutCallCount = 0
    public var passwordResetEmails: [String] = []
    public var updatedPasswords: [String] = []
    public var recoveryURLs: [URL] = []

    /// O teste empurra eventos por aqui, e o ViewModel reage como reagiria em
    /// produção — que era exatamente o que não dava para fazer quando ele lia o
    /// stream do cliente Supabase direto.
    public let stateContinuation: AsyncStream<(event: AuthChangeEvent, session: Session?)>.Continuation
    private let stream: AsyncStream<(event: AuthChangeEvent, session: Session?)>

    public init() {
        var continuation: AsyncStream<(event: AuthChangeEvent, session: Session?)>.Continuation!
        stream = AsyncStream { continuation = $0 }
        stateContinuation = continuation
    }

    public var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> { stream }

    private func failIfNeeded(_ code: Int, _ message: String) throws {
        if shouldThrowError {
            throw NSError(domain: "TestMockAuthService", code: code,
                          userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    public func signInWithApple(idToken: String, nonce: String) async throws -> User {
        try failIfNeeded(1, "Apple sign-in failed")
        return try requireUser()
    }

    public var signedInEmails: [String] = []
    public var signedUpEmails: [String] = []

    public func signInWithEmail(email: String, password: String) async throws -> User {
        try failIfNeeded(9, "Sign-in failed")
        signedInEmails.append(email)
        return try requireUser()
    }

    public func signUpWithEmail(email: String, password: String) async throws -> User {
        try failIfNeeded(10, "Sign-up failed")
        signedUpEmails.append(email)
        return try requireUser()
    }

    private func requireUser() throws -> User {
        guard let user = sessionToReturn?.user else {
            throw NSError(domain: "TestMockAuthService", code: 99,
                          userInfo: [NSLocalizedDescriptionKey: "No session configured"])
        }
        return user
    }

    public func signOut() async throws {
        signOutCallCount += 1
        try failIfNeeded(2, "Sign-out failed")
    }

    public func getCurrentSession() async throws -> Session {
        try failIfNeeded(3, "No session")
        guard let sessionToReturn else {
            throw NSError(domain: "TestMockAuthService", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "No session"])
        }
        return sessionToReturn
    }

    public func deleteAccount() async throws {
        try failIfNeeded(5, "Delete failed")
    }

    public func sendPasswordReset(email: String) async throws {
        try failIfNeeded(6, "Reset failed")
        passwordResetEmails.append(email)
    }

    public func completePasswordRecovery(from url: URL) async throws {
        try failIfNeeded(7, "Recovery link invalid")
        recoveryURLs.append(url)
    }

    public func updatePassword(_ newPassword: String) async throws {
        try failIfNeeded(8, "Password update failed")
        updatedPasswords.append(newPassword)
    }
}
