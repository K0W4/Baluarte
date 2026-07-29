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
        } catch {
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
        }
    }
    
    @MainActor
    public func signInWithApple() async {
        self.state = .loading
        
        AppleSignInHelper.shared.startSignIn { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let credentials):
                    do {
                        let user = try await self.authService.signInWithApple(idToken: credentials.idToken, nonce: credentials.nonce)
                        let member = try await self.memberService.fetchMember(id: user.id)
                        self.state = .authenticated(user, member)
                        UserDefaultsManager.shared.currentUserId = user.id
                        UserDefaultsManager.shared.currentChapterId = member?.chapterId
                    } catch {
                        self.state = .unauthenticated
                        self.errorMessage = AppError.from(error).userMessage
                        UserDefaultsManager.shared.currentUserId = nil
                        UserDefaultsManager.shared.currentChapterId = nil
                    }
                case .failure(let error):
                    self.state = .unauthenticated
                    self.errorMessage = AppError.from(error).userMessage
                    UserDefaultsManager.shared.currentUserId = nil
                    UserDefaultsManager.shared.currentChapterId = nil
                }
            }
        }
    }
    
    @MainActor
    public func signInWithEmail(email: String, password: String) async {
        self.state = .loading
        do {
            let user = try await authService.signInWithEmail(email: email, password: password)
            let member = try await memberService.fetchMember(id: user.id)
            self.state = .authenticated(user, member)
            UserDefaultsManager.shared.currentUserId = user.id
            UserDefaultsManager.shared.currentChapterId = member?.chapterId
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
        }
    }
    
    @MainActor
    public func signUpWithEmail(email: String, password: String) async {
        self.state = .loading
        do {
            let user = try await authService.signUpWithEmail(email: email, password: password)
            self.state = .authenticated(user, nil)
            UserDefaultsManager.shared.currentUserId = user.id
            UserDefaultsManager.shared.currentChapterId = nil
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
        }
    }
    
    @MainActor
    public func completeProfile(fullName: String, cid: String, birthDate: Date, isActive: Bool, isSenior: Bool, isMason: Bool) async {
        guard case let .authenticated(user, member) = self.state else { return }
        
        self.state = .loading
        
        do {
            var updatedMember: Member
            if var existingMember = member {
                existingMember.fullName = fullName
                existingMember.cid = cid
                existingMember.birthdate = birthDate
                existingMember.isActive = isActive
                existingMember.isSenior = isSenior
                existingMember.isMason = isMason
                try await memberService.updateMember(existingMember)
                updatedMember = existingMember
            } else {
                updatedMember = Member(
                    id: user.id,
                    chapterId: nil,
                    fullName: fullName,
                    role: nil,
                    isActive: isActive,
                    isSenior: isSenior,
                    isMason: isMason,
                    accessLevel: "Membro",
                    birthdate: birthDate,
                    cid: cid,
                    createdAt: Date()
                )
                try await memberService.createMember(updatedMember)
            }
            self.state = .authenticated(user, updatedMember)
            UserDefaultsManager.shared.currentUserId = user.id
            UserDefaultsManager.shared.currentChapterId = updatedMember.chapterId
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .authenticated(user, member)
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
        guard let userId = currentUserId else { return }
        
        self.state = .loading
        do {
            // Apaga os dados do membro no banco (Soft Delete do ponto de vista de Auth)
            try await memberService.deleteMember(memberId: userId)
            
            // Faz o sign out para deslogar da sessão local
            try await authService.signOut()
            
            self.state = .unauthenticated
            UserDefaultsManager.shared.currentUserId = nil
            UserDefaultsManager.shared.currentChapterId = nil
        } catch {
            self.errorMessage = AppError.from(error).userMessage
            self.state = .unauthenticated // Força o sign out mesmo se falhar a deleção por segurança local
        }
    }
}
