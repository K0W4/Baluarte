import Foundation
import Supabase
import SwiftUI

@Observable
public final class AuthViewModel {
    public enum AuthState {
        case loading
        case unauthenticated
        case authenticated(User, UserProfile?)
    }

    public enum RootRoute: String, Equatable {
        case loading
        case unauthenticated
        case chapterSelection
        case pendingApproval
        case rejected
        case app
    }

    public var state: AuthState = .loading
    public var errorMessage: String?

    /// Sobreposto a qualquer rota: quem chega por um link de recuperação pode estar
    /// deslogado, dentro do app, ou parado na fila de aprovação.
    public var isSettingNewPassword = false

    public private(set) var memberships: [ChapterMembership] = []
    public private(set) var activeMembership: ChapterMembership?
    public private(set) var pendingRequest: JoinRequest?
    public private(set) var pendingRequestChapter: Chapter?
    public private(set) var activeChapter: Chapter?
    public private(set) var rejectedRequest: JoinRequest?
    public private(set) var rejectedRequestChapter: Chapter?

    /// A code captured from a shared link before the person is ready to redeem it.
    public var pendingInviteCode: String?

    public var activeChapterName: String { activeChapter?.name ?? "seu Capítulo" }

    public var currentChapterId: UUID? { activeMembership?.chapterId }

    /// The chapter-scoped actor id. Use this, not `currentUserId`, wherever the value
    /// is stored on a chapter row — committee members, task assignee/creator, attendance.
    public var currentMembershipId: UUID? { activeMembership?.id }

    public var currentUserId: UUID? {
        if case let .authenticated(user, _) = state { return user.id }
        return nil
    }

    public var currentProfile: UserProfile? {
        if case let .authenticated(_, profile) = state { return profile }
        return nil
    }

    public var accessLevel: AccessLevel { activeMembership?.accessLevel ?? .member }

    public var isPlatformAdmin: Bool { currentProfile?.isPlatformAdmin ?? false }

    public var permissions: PermissionSet {
        PermissionSet(accessLevel: accessLevel, isPlatformAdmin: isPlatformAdmin)
    }

    public var route: RootRoute {
        switch state {
        case .loading:
            return .loading
        case .unauthenticated:
            return .unauthenticated
        case .authenticated:
            if activeMembership != nil { return .app }
            if pendingRequest != nil { return .pendingApproval }
            return rejectedRequest == nil ? .chapterSelection : .rejected
        }
    }

    private let authService: AuthServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let membershipService: MembershipServiceProtocol
    private let joinRequestService: JoinRequestServiceProtocol
    private let chapterService: ChapterServiceProtocol
    private let sessionStore: SessionStoreProtocol

    private var authStateTask: Task<Void, Never>?

    public init(
        authService: AuthServiceProtocol = AuthService(),
        profileService: ProfileServiceProtocol = Services.profile,
        membershipService: MembershipServiceProtocol = Services.membership,
        joinRequestService: JoinRequestServiceProtocol = Services.joinRequest,
        chapterService: ChapterServiceProtocol = Services.chapter,
        sessionStore: SessionStoreProtocol = Services.sessionStore
    ) {
        self.authService = authService
        self.profileService = profileService
        self.membershipService = membershipService
        self.joinRequestService = joinRequestService
        self.chapterService = chapterService
        self.sessionStore = sessionStore
        Task {
            await checkSession()
        }
        observeAuthStateChanges()
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Shared state

    /// The app group and keychain are the widget's and the AppIntents' only view of the
    /// session. Writing them from exactly one place is what stops them drifting.
    @MainActor
    private func syncSharedState(session: Session?) {
        guard let session else {
            sessionStore.clear()
            return
        }

        sessionStore.save(
            userId: currentUserId,
            chapterId: currentChapterId,
            membershipId: currentMembershipId,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
    }

    /// Supabase refreshes the access token on its own schedule. Without this the widget
    /// keeps reading whatever token was written at sign-in and goes stale within the hour.
    private func observeAuthStateChanges() {
        // @MainActor explícito: `syncSharedState` já é isolado nele, e deixar a
        // isolação implícita fazia o compilador apontar um `await` sem efeito.
        // O stream é capturado antes da Task: a propriedade cria um novo a cada
        // acesso, e lê-la de dentro exigiria `self` antes do `guard let self`.
        let changes = authService.authStateChanges
        authStateTask = Task { @MainActor [weak self] in
            for await (event, session) in changes {
                guard let self else { return }
                switch event {
                case .tokenRefreshed, .signedIn, .initialSession:
                    if let session {
                        self.syncSharedState(session: session)
                    }
                case .passwordRecovery:
                    self.isSettingNewPassword = true
                case .signedOut:
                    self.sessionStore.clear()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Session loading

    @MainActor
    private func loadMemberships(for user: User, profile: UserProfile) async throws {
        let fetched = try await membershipService.fetchMemberships(for: user.id)
        self.memberships = fetched
        self.activeMembership = fetched.first { $0.chapterId == profile.activeChapterId }
            ?? fetched.first

        if let activeMembership {
            self.pendingRequest = nil
            self.pendingRequestChapter = nil
            self.rejectedRequest = nil
            self.rejectedRequestChapter = nil
            self.activeChapter = try await chapterService.fetchChapter(id: activeMembership.chapterId)
            return
        }

        self.activeChapter = nil

        // Sem vínculo, a pessoa está escolhendo um Capítulo, esperando resposta, ou
        // acabou de ser recusada. Qual dos três decide a rota inteira — e a recusa é o
        // caso que antes sumia sem explicação.
        let request = try await joinRequestService.fetchMyPendingRequest(memberId: user.id)
        self.pendingRequest = request
        self.pendingRequestChapter = if let chapterId = request?.chapterId {
            try await chapterService.fetchChapter(id: chapterId)
        } else {
            nil
        }

        guard request == nil else {
            self.rejectedRequest = nil
            self.rejectedRequestChapter = nil
            return
        }

        let rejected = try await joinRequestService.fetchMyLatestRejectedRequest(memberId: user.id)
        self.rejectedRequest = rejected
        self.rejectedRequestChapter = if let chapterId = rejected?.chapterId {
            try await chapterService.fetchChapter(id: chapterId)
        } else {
            nil
        }
    }

    @MainActor
    public func acknowledgeRejection() async {
        guard let rejected = rejectedRequest else { return }

        errorMessage = nil
        do {
            try await joinRequestService.acknowledgeRejection(id: rejected.id)
            self.rejectedRequest = nil
            self.rejectedRequestChapter = nil
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
    }

    @MainActor
    private func establishSession(for user: User, fallbackName: String?) async throws {
        let profile: UserProfile
        if let existing = try await profileService.fetchProfile(id: user.id) {
            profile = existing
        } else {
            let newProfile = UserProfile(
                id: user.id,
                fullName: fallbackName ?? "Membro DeMolay",
                createdAt: Date()
            )
            try await profileService.createProfile(newProfile)
            profile = newProfile
        }

        try await loadMemberships(for: user, profile: profile)
        self.state = .authenticated(user, profile)

        let session = try await authService.getCurrentSession()
        syncSharedState(session: session)
    }

    @MainActor
    private func failSession(with error: Error) {
        self.errorMessage = AppError.from(error).userMessage
        self.state = .unauthenticated
        self.memberships = []
        self.activeMembership = nil
        sessionStore.clear()
    }

    @MainActor
    public func checkSession() async {
        do {
            let session = try await authService.getCurrentSession()
            try await establishSession(for: session.user, fallbackName: nil)
        } catch {
            self.state = .unauthenticated
            self.memberships = []
            self.activeMembership = nil
            sessionStore.clear()
        }
    }

    // MARK: - Sign in

    @MainActor
    public func signInWithApple(credentials: AppleCredentials) async {
        self.state = .loading
        do {
            let user = try await authService.signInWithApple(
                idToken: credentials.idToken,
                nonce: credentials.nonce
            )
            try await establishSession(for: user, fallbackName: credentials.fullName)
        } catch {
            failSession(with: error)
        }
    }

    @MainActor
    public func failAppleSignIn(with error: Error) {
        self.state = .unauthenticated
        self.errorMessage = AppError.from(error).userMessage
    }

    @MainActor
    public func signInWithEmail(email: String, password: String) async {
        self.state = .loading
        do {
            let user = try await authService.signInWithEmail(email: email, password: password)
            try await establishSession(for: user, fallbackName: nil)
        } catch {
            failSession(with: error)
        }
    }

    @MainActor
    public func signUpWithEmail(email: String, password: String) async {
        self.state = .loading
        do {
            let user = try await authService.signUpWithEmail(email: email, password: password)
            try await establishSession(for: user, fallbackName: nil)
        } catch {
            failSession(with: error)
        }
    }

    @MainActor
    public func beginPasswordRecovery(from url: URL) async {
        errorMessage = nil
        do {
            try await authService.completePasswordRecovery(from: url)
            isSettingNewPassword = true
        } catch {
            // O link expira e só pode ser usado uma vez. Dizer isso é mais útil do
            // que a mensagem do servidor, que fala de token.
            errorMessage = String(localized: "Este link de recuperação expirou ou já foi usado. Peça um novo.")
        }
    }

    @MainActor
    public func setNewPassword(_ newPassword: String) async -> Bool {
        errorMessage = nil
        do {
            try await authService.updatePassword(newPassword)
            isSettingNewPassword = false
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }

    public func sendPasswordReset(to email: String) async -> Bool {
        errorMessage = nil
        do {
            try await authService.sendPasswordReset(email: email)
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }

    // MARK: - Chapter membership

    @MainActor
    public func requestToJoin(_ chapter: Chapter, message: String? = nil) async -> Bool {
        guard case let .authenticated(user, profile) = self.state, let profile else { return false }

        errorMessage = nil
        do {
            let request = try await joinRequestService.createRequest(
                chapterId: chapter.id,
                memberId: user.id,
                message: message,
                cid: profile.cid
            )
            self.pendingRequest = request
            self.pendingRequestChapter = chapter
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            return false
        }
    }

    @MainActor
    public func cancelJoinRequest() async {
        guard let request = pendingRequest else { return }

        errorMessage = nil
        do {
            try await joinRequestService.cancelRequest(id: request.id)
            self.pendingRequest = nil
            self.pendingRequestChapter = nil
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
    }

    /// Called from the pending screen so an approval that happened elsewhere shows up
    /// without the person having to guess when to reopen the app.
    @MainActor
    public func refreshMembershipState() async {
        guard case let .authenticated(user, profile) = self.state, let profile else { return }
        do {
            try await loadMemberships(for: user, profile: profile)
            if activeMembership != nil {
                let session = try await authService.getCurrentSession()
                syncSharedState(session: session)
            }
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
    }

    /// Dupla filiação: o schema é N:N desde a Fase 0, mas até aqui a interface só
    /// mostrava um vínculo. `active_chapter_id` é o que decide qual está aberto.
    @MainActor
    public func switchChapter(to membership: ChapterMembership) async {
        guard case let .authenticated(user, profile) = self.state,
              let profile,
              membership.id != activeMembership?.id else { return }

        errorMessage = nil
        do {
            try await profileService.updateActiveChapter(memberId: user.id, chapterId: membership.chapterId)

            var updatedProfile = profile
            updatedProfile.activeChapterId = membership.chapterId

            self.activeMembership = membership
            self.state = .authenticated(user, updatedProfile)
            self.activeChapter = try await chapterService.fetchChapter(id: membership.chapterId)

            let session = try await authService.getCurrentSession()
            syncSharedState(session: session)
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
    }

    @MainActor
    public func leaveChapter() async {
        guard case let .authenticated(user, profile) = self.state,
              let profile,
              let membership = activeMembership else { return }

        errorMessage = nil
        do {
            try await membershipService.leaveChapter(chapterId: membership.chapterId)
            memberships.removeAll { $0.id == membership.id }

            var updatedProfile = profile
            updatedProfile.activeChapterId = memberships.first?.chapterId

            self.activeMembership = memberships.first
            self.state = .authenticated(user, updatedProfile)

            let session = try await authService.getCurrentSession()
            syncSharedState(session: session)
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
    }

    // MARK: - Profile

    @MainActor
    public func updateProfile(fullName: String, cid: String, birthdate: Date?) async -> Bool {
        guard case let .authenticated(user, profile) = self.state, var updatedProfile = profile else {
            return false
        }

        errorMessage = nil
        do {
            updatedProfile.fullName = fullName
            updatedProfile.cid = cid.isEmpty ? nil : cid
            updatedProfile.birthdate = birthdate
            try await profileService.updateProfile(updatedProfile)

            self.state = .authenticated(user, updatedProfile)
            if var membership = activeMembership {
                membership.fullName = fullName
                self.activeMembership = membership
            }
            return true
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            return false
        }
    }

    // MARK: - Sign out

    @MainActor
    public func signOut() async {
        self.state = .loading
        do {
            try await authService.signOut()
        } catch {
            self.errorMessage = AppError.from(error).userMessage
        }
        self.state = .unauthenticated
        self.memberships = []
        self.activeMembership = nil
        sessionStore.clear()
    }

    @MainActor
    public func deleteAccount() async {
        guard currentUserId != nil else { return }

        self.state = .loading
        do {
            try await authService.deleteAccount()
            try await authService.signOut()
        } catch {
            self.errorMessage = AppError.from(error).userMessage
        }

        self.state = .unauthenticated
        self.memberships = []
        self.activeMembership = nil
        sessionStore.clear()
    }
}
