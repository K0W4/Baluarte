import Foundation
import Supabase

public protocol AuthServiceProtocol {
    func signInWithApple(idToken: String, nonce: String) async throws -> User
    func signInWithEmail(email: String, password: String) async throws -> User
    func signUpWithEmail(email: String, password: String) async throws -> User
    func signOut() async throws
    func getCurrentSession() async throws -> Session
    func deleteAccount() async throws
    func sendPasswordReset(email: String) async throws
    /// Troca o link do e-mail por uma sessão. Sem isto o token não vira nada, e a
    /// pessoa fica diante de uma tela que não consegue salvar.
    func completePasswordRecovery(from url: URL) async throws
    func updatePassword(_ newPassword: String) async throws

    /// O Supabase renova o access token no ritmo dele. Sem escutar isto, o widget
    /// segue lendo o token gravado no login e envelhece dentro de uma hora.
    ///
    /// Está no protocolo, e não lido direto do cliente, porque era o que tornava o
    /// `AuthViewModel` impossível de instanciar num teste sem rede.
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> { get }
}

public class AuthService: AuthServiceProtocol {
    private let client = SupabaseManager.shared.client
    
    public init() {}
    
    public func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let response = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        return response.user
    }
    
    public func signInWithEmail(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(email: email, password: password)
        return session.user
    }
    
    public func signUpWithEmail(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.user
    }
    
    public func signOut() async throws {
        try await client.auth.signOut()
    }
    
    public func getCurrentSession() async throws -> Session {
        return try await client.auth.session
    }

    public func deleteAccount() async throws {
        try await client.functions.invoke("delete-account")
    }

    public func sendPasswordReset(email: String) async throws {
        // Sem redirectTo o Supabase cai no Site URL do projeto, que não tem para onde
        // apontar: não há domínio. O scheme do próprio app é o destino.
        try await client.auth.resetPasswordForEmail(email, redirectTo: DeepLink.passwordRecoveryURL)
    }

    public func completePasswordRecovery(from url: URL) async throws {
        _ = try await client.auth.session(from: url)
    }

    public func updatePassword(_ newPassword: String) async throws {
        _ = try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    public var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in client.auth.authStateChanges {
                    continuation.yield((event: event, session: session))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
