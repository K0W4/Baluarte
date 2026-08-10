#if DEBUG
import Foundation
import Supabase

// MARK: - O ambiente determinístico dos testes de interface
//
// Os testes que existiam antes disto não provavam nada: dois eram o esqueleto do
// template e o terceiro envolvia tudo num `if elemento.waitForExistence`, então
// passava verde quando a tela nem tinha carregado. Um teste de interface que depende
// de uma sessão real e de dados no servidor é um teste que falha por motivo errado --
// ou, pior, que passa por motivo errado.
//
// O que torna isto possível já existia: o `AuthViewModel` recebe todo serviço por
// parâmetro de init com tipo de protocolo (pacote 8), e o app group e o Keychain
// vivem atrás de `SessionStoreProtocol`. Aqui só se troca a implementação.
//
// Fica todo dentro de `#if DEBUG`: o binário da loja não carrega uma linha disto.
//
// As telas exercitadas -- rotas, `ChapterView`, `ProfileView`, `PlatformView` e as
// affordances que somem sem permissão -- leem do `AuthViewModel` e de mais nada, e é
// por isso que trocar seis serviços basta. `Services.event` e companhia continuam
// apontando para o Supabase; a tela inicial mostra o próprio banner de erro, e nenhum
// teste depende do conteúdo dela.

public struct UITestConfiguration {
    public enum Route: String {
        case unauthenticated
        case chapterSelection
        case pendingApproval
        case rejected
        case app
    }

    public let route: Route
    public let accessLevel: AccessLevel
    public let chapterCount: Int
    public let isPlatformAdmin: Bool

    /// Nulo quando o app foi aberto normalmente. É a única porta de entrada deste
    /// arquivo inteiro.
    public static var fromLaunchArguments: UITestConfiguration? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-uitest") else { return nil }

        func value(for flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }

        return UITestConfiguration(
            route: value(for: "-uitest-route").flatMap(Route.init(rawValue:)) ?? .app,
            accessLevel: value(for: "-uitest-access").flatMap(AccessLevel.init(rawValue:)) ?? .owner,
            chapterCount: value(for: "-uitest-chapters").flatMap(Int.init) ?? 1,
            isPlatformAdmin: arguments.contains("-uitest-platform-admin")
        )
    }

    public func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            authService: UITestAuthService(configuration: self),
            profileService: UITestProfileService(configuration: self),
            membershipService: UITestMembershipService(configuration: self),
            joinRequestService: UITestJoinRequestService(configuration: self),
            chapterService: UITestChapterService(configuration: self),
            sessionStore: UITestSessionStore()
        )
    }
}

// MARK: - Dados fixos
//
// Ids fixos e não sorteados: um teste que compara a tela contra um dado diferente a
// cada execução não é reproduzível, e o `Math.random` do dia seguinte é o bug que
// ninguém consegue repetir.

public enum UITestFixtures {
    public static let userId = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1") ?? UUID()
    public static let firstChapterId = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1") ?? UUID()
    public static let secondChapterId = UUID(uuidString: "00000000-0000-0000-0000-0000000000C2") ?? UUID()
    public static let firstMembershipId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1") ?? UUID()
    public static let secondMembershipId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2") ?? UUID()
    public static let requestId = UUID(uuidString: "00000000-0000-0000-0000-0000000000D1") ?? UUID()

    public static let personName = "Gabriel de Teste"
    public static let firstChapterName = "Capítulo Alfa"
    public static let secondChapterName = "Capítulo Beta"
    public static let rejectionReason = "O CID informado não confere com o cadastro."

    public static let epoch = Date(timeIntervalSince1970: 1_767_225_600)

    public static func chapter(id: UUID, name: String, number: Int) -> Chapter {
        Chapter(
            id: id, name: name, number: number, uf: "RS", city: "Porto Alegre",
            status: .active, hasOwner: true, createdAt: epoch
        )
    }

    public static func membership(id: UUID, chapterId: UUID, accessLevel: AccessLevel) -> ChapterMembership {
        ChapterMembership(
            id: id, chapterId: chapterId, memberId: userId,
            fullName: personName, category: .ativo, role: "Mestre Conselheiro",
            accessLevel: accessLevel, status: .active, joinedAt: epoch, createdAt: epoch
        )
    }

    /// `Session` e `User` do `supabase-swift` têm dezenas de campos e um inicializador
    /// que muda de versão para versão. Decodificar de JSON é o que envelhece junto com
    /// o contrato do servidor em vez de contra ele.
    public static func session() -> Session? {
        let json = """
        {
          "access_token": "uitest-access-token",
          "token_type": "bearer",
          "expires_in": 3600,
          "expires_at": 4102444800,
          "refresh_token": "uitest-refresh-token",
          "user": {
            "id": "\(userId.uuidString)",
            "app_metadata": {},
            "user_metadata": {},
            "aud": "authenticated",
            "email": "teste@baluarte.app",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
            "is_anonymous": false
          }
        }
        """

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Session.self, from: Data(json.utf8))
    }
}

/// O onboarding e o "primeiro lançamento" são `@AppStorage`, então sobrevivem entre
/// execuções e decidiriam qual tela o teste vê. Zerá-los na abertura é o que faz cada
/// execução começar do mesmo lugar.
public enum UITestLaunch {
    public static func resetPersistedFlags() {
        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        // A rota de onboarding é a única que quer o contrário, e pede por argumento.
        if ProcessInfo.processInfo.arguments.contains("-uitest-fresh-onboarding") {
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        }
    }
}

private struct UITestError: LocalizedError {
    var errorDescription: String? { "Sem sessão no ambiente de teste." }
}

// MARK: - Serviços

final class UITestAuthService: AuthServiceProtocol {
    private let configuration: UITestConfiguration
    private let stream: AsyncStream<(event: AuthChangeEvent, session: Session?)>

    init(configuration: UITestConfiguration) {
        self.configuration = configuration
        // Um stream que nunca emite: quem dita o estado é `getCurrentSession`, e um
        // evento a mais aqui só reintroduziria corrida no que existe para ser estável.
        stream = AsyncStream { _ in }
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> { stream }

    func getCurrentSession() async throws -> Session {
        guard configuration.route != .unauthenticated, let session = UITestFixtures.session() else {
            throw UITestError()
        }
        return session
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> User { try await getCurrentSession().user }
    func signInWithEmail(email: String, password: String) async throws -> User { try await getCurrentSession().user }
    func signUpWithEmail(email: String, password: String) async throws -> User { try await getCurrentSession().user }
    func signOut() async throws {}
    func deleteAccount() async throws {}
    func sendPasswordReset(email: String) async throws {}
    func completePasswordRecovery(from url: URL) async throws {}
    func updatePassword(_ newPassword: String) async throws {}
}

final class UITestProfileService: ProfileServiceProtocol {
    private let configuration: UITestConfiguration

    init(configuration: UITestConfiguration) {
        self.configuration = configuration
    }

    func fetchProfile(id: UUID) async throws -> UserProfile? {
        UserProfile(
            id: UITestFixtures.userId,
            fullName: UITestFixtures.personName,
            cid: "5820",
            birthdate: UITestFixtures.epoch,
            activeChapterId: configuration.route == .app ? UITestFixtures.firstChapterId : nil,
            isPlatformAdmin: configuration.isPlatformAdmin,
            createdAt: UITestFixtures.epoch
        )
    }

    func createProfile(_ profile: UserProfile) async throws {}
    func updateProfile(_ profile: UserProfile) async throws {}
    func updateActiveChapter(memberId: UUID, chapterId: UUID?) async throws {}
}

final class UITestMembershipService: MembershipServiceProtocol {
    private let configuration: UITestConfiguration

    init(configuration: UITestConfiguration) {
        self.configuration = configuration
    }

    func fetchMemberships(for memberId: UUID) async throws -> [ChapterMembership] {
        guard configuration.route == .app else { return [] }

        var memberships = [
            UITestFixtures.membership(
                id: UITestFixtures.firstMembershipId,
                chapterId: UITestFixtures.firstChapterId,
                accessLevel: configuration.accessLevel
            )
        ]

        if configuration.chapterCount > 1 {
            memberships.append(
                UITestFixtures.membership(
                    id: UITestFixtures.secondMembershipId,
                    chapterId: UITestFixtures.secondChapterId,
                    accessLevel: .member
                )
            )
        }

        return memberships
    }

    func leaveChapter(chapterId: UUID) async throws {}
    func setAccessLevel(membershipId: UUID, level: AccessLevel) async throws {}
    func transferOwnership(toMembershipId: UUID) async throws {}
    func platformAdmins() async throws -> [PlatformAdmin] { [] }
    func grantPlatformAdmin(cid: String) async throws {}
    func revokePlatformAdmin(memberId: UUID) async throws {}
}

final class UITestJoinRequestService: JoinRequestServiceProtocol {
    private let configuration: UITestConfiguration

    init(configuration: UITestConfiguration) {
        self.configuration = configuration
    }

    private func request(status: JoinRequestStatus, reason: String?) -> JoinRequest {
        JoinRequest(
            id: UITestFixtures.requestId,
            chapterId: UITestFixtures.firstChapterId,
            memberId: UITestFixtures.userId,
            status: status,
            message: nil,
            cidSnapshot: "5820",
            createdAt: UITestFixtures.epoch,
            rejectReason: reason
        )
    }

    func fetchMyPendingRequest(memberId: UUID) async throws -> JoinRequest? {
        configuration.route == .pendingApproval ? request(status: .pending, reason: nil) : nil
    }

    func fetchMyLatestRejectedRequest(memberId: UUID) async throws -> JoinRequest? {
        configuration.route == .rejected
            ? request(status: .rejected, reason: UITestFixtures.rejectionReason)
            : nil
    }

    func createRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?) async throws -> JoinRequest {
        request(status: .pending, reason: nil)
    }

    func acknowledgeRejection(id: UUID) async throws {}
    func fetchPendingRequests(for chapterId: UUID) async throws -> [PendingJoinRequest] { [] }
    func cancelRequest(id: UUID) async throws {}
    func approve(requestId: UUID, accessLevel: AccessLevel, category: MembershipCategory, role: String?, linkMembershipId: UUID?) async throws {}
    func reject(requestId: UUID, reason: String?) async throws {}

    func uploadProof(memberId: UUID, imageData: Data) async throws -> String { "uitest/proof.jpg" }
    func createBootstrapRequest(chapterId: UUID, memberId: UUID, message: String?, cid: String?, proofPath: String) async throws -> JoinRequest {
        request(status: .pending, reason: nil)
    }
    func fetchPendingBootstrapRequests() async throws -> [BootstrapRequest] { [] }
    func signedProofURL(path: String) async throws -> URL {
        URL(string: "https://example.invalid/proof.jpg") ?? URL(fileURLWithPath: "/dev/null")
    }
}

final class UITestChapterService: ChapterServiceProtocol {
    private let configuration: UITestConfiguration

    init(configuration: UITestConfiguration) {
        self.configuration = configuration
    }

    private var chapters: [Chapter] {
        [
            UITestFixtures.chapter(id: UITestFixtures.firstChapterId, name: UITestFixtures.firstChapterName, number: 656),
            UITestFixtures.chapter(id: UITestFixtures.secondChapterId, name: UITestFixtures.secondChapterName, number: 42)
        ]
    }

    func fetchChapter(id: UUID) async throws -> Chapter? {
        chapters.first { $0.id == id }
    }

    func searchChapters(query: String?, uf: String?) async throws -> [Chapter] { chapters }
    func requestChapter(_ request: ChapterRequest) async throws {}
    func pendingChapterRequests() async throws -> [PendingChapterRequest] { [] }
    func reviewChapterRequest(id: UUID, approved: Bool, reason: String?) async throws {}
}

/// Sem isto o teste escreve no app group e no Keychain de verdade, e a execução
/// seguinte começa suja.
final class UITestSessionStore: SessionStoreProtocol {
    func save(
        userId: UUID?, chapterId: UUID?, membershipId: UUID?,
        chapters: [WidgetChapter],
        accessToken: String, refreshToken: String
    ) {}

    func clear() {}
}
#endif
