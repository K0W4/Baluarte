import Foundation
import Supabase
import SwiftUI

@Observable
public final class AuthViewModel {
    public enum AuthState {
        case loading
        case unauthenticated
        case authenticated(User, Member?)
    }
    
    public var state: AuthState = .loading
    public var errorMessage: String?
    
    public var currentChapterId: UUID? {
        if case let .authenticated(_, member) = state {
            return member?.chapterId
        }
        return nil
    }
    
    public var currentUserId: UUID? {
        if case let .authenticated(user, _) = state {
            return user.id
        }
        return nil
    }
    
    private let authService: AuthServiceProtocol
    private let memberService: MemberServiceProtocol
    
    public init(authService: AuthServiceProtocol = AuthService(), memberService: MemberServiceProtocol = Services.member) {
        self.authService = authService
        self.memberService = memberService
        Task {
            await checkSession()
        }
    }
    
    @MainActor
    public func checkSession() async {
        do {
            let session = try await authService.getCurrentSession()
            let member = try await memberService.fetchMember(id: session.user.id)
            self.state = .authenticated(session.user, member)
            UserDefaultsManager.shared.currentUserId = session.user.id
            UserDefaultsManager.shared.currentChapterId = member?.chapterId
            UserDefaultsManager.shared.accessToken = session.accessToken
        } catch {
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
            UserDefaultsManager.shared.accessToken = nil
        }
    }
    
    @MainActor
    public func signInWithApple(credentials: AppleCredentials) async {
        self.state = .loading

        do {
            let user = try await authService.signInWithApple(idToken: credentials.idToken, nonce: credentials.nonce)
            let fetchedMember = try await memberService.fetchMember(id: user.id)

            let member: Member
            if let existing = fetchedMember {
                member = existing
            } else {
                let newMember = Member(
                    id: user.id,
                    chapterId: nil,
                    fullName: credentials.fullName ?? "Membro DeMolay",
                    role: nil,
                    isActive: false,
                    isSenior: false,
                    isMason: false,
                    accessLevel: "Membro",
                    birthdate: nil,
                    cid: nil,
                    createdAt: Date()
                )
                try await memberService.createMember(newMember)
                member = newMember
            }

            self.state = .authenticated(user, member)
            let session = try await authService.getCurrentSession()
            UserDefaultsManager.shared.currentUserId = user.id
            UserDefaultsManager.shared.currentChapterId = member.chapterId
            UserDefaultsManager.shared.accessToken = session.accessToken
        } catch {
            self.state = .unauthenticated
            self.errorMessage = AppError.from(error).userMessage
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
            UserDefaultsManager.shared.accessToken = nil
        }
    }

    @MainActor
    public func failAppleSignIn(with error: Error) {
        self.state = .unauthenticated
        self.errorMessage = AppError.from(error).userMessage
    }

    @MainActor
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
    
    @MainActor
    public func signInWithEmail(email: String, password: String) async {
        self.state = .loading
        do {
            let user = try await authService.signInWithEmail(email: email, password: password)
            let fetchedMember = try await memberService.fetchMember(id: user.id)
            
            let member: Member
            if let existing = fetchedMember {
                member = existing
            } else {
                let newMember = Member(
                    id: user.id,
                    chapterId: nil,
                    fullName: "Membro DeMolay",
                    role: nil,
                    isActive: false,
                    isSenior: false,
                    isMason: false,
                    accessLevel: "Membro",
                    birthdate: nil,
                    cid: nil,
                    createdAt: Date()
                )
                try await memberService.createMember(newMember)
                member = newMember
            }
            
            self.state = .authenticated(user, member)
            let session = try await authService.getCurrentSession()
            UserDefaultsManager.shared.currentUserId = user.id
            UserDefaultsManager.shared.currentChapterId = member.chapterId
            UserDefaultsManager.shared.accessToken = session.accessToken
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
            UserDefaultsManager.shared.accessToken = nil
        }
    }
    
    @MainActor
    public func signUpWithEmail(email: String, password: String) async {
        self.state = .loading
        do {
            let user = try await authService.signUpWithEmail(email: email, password: password)
            
            let newMember = Member(
                id: user.id,
                chapterId: nil,
                fullName: "Membro DeMolay",
                role: nil,
                isActive: false,
                isSenior: false,
                isMason: false,
                accessLevel: "Membro",
                birthdate: nil,
                cid: nil,
                createdAt: Date()
            )
            try await memberService.createMember(newMember)
            
            self.state = .authenticated(user, newMember)
            let session = try await authService.getCurrentSession()
            UserDefaultsManager.shared.currentUserId = user.id
            UserDefaultsManager.shared.currentChapterId = nil
            UserDefaultsManager.shared.accessToken = session.accessToken
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
            UserDefaultsManager.shared.accessToken = nil
        }
    }
    
    @MainActor
    public func updateProfile(fullName: String, cid: String, birthdate: Date?) async -> Bool {
        guard case let .authenticated(user, member) = self.state, var existingMember = member else { return false }
        
        do {
            existingMember.fullName = fullName
            existingMember.cid = cid
            existingMember.birthdate = birthdate
            try await memberService.updateMember(existingMember)
            self.state = .authenticated(user, existingMember)
            return true
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            return false
        }
    }
    
    @MainActor
    public func signOut() async {
        self.state = .loading
        do {
            try await authService.signOut()
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
            UserDefaultsManager.shared.accessToken = nil
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .unauthenticated
        }
    }
    
    @MainActor
    public func leaveChapter() async {
        guard case let .authenticated(user, member) = self.state, var currentMember = member else { return }
        
        self.state = .loading
        do {
            currentMember.chapterId = nil
            try await memberService.updateMember(currentMember)
            
            self.state = .authenticated(user, currentMember)
            UserDefaultsManager.shared.currentChapterId = nil
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .authenticated(user, member)
        }
    }
    
    @MainActor
    public func deleteAccount() async {
        guard currentUserId != nil else { return }

        self.state = .loading
        do {
            try await authService.deleteAccount()
            try await authService.signOut()

            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
            UserDefaultsManager.shared.accessToken = nil
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .unauthenticated // Força o sign out mesmo se falhar a deleção por segurança local
        }
    }
}
