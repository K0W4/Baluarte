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
        } catch {
            self.state = .unauthenticated
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
                    } catch {
                        self.state = .unauthenticated
                        self.errorMessage = error.localizedDescription
                    }
                case .failure(let error):
                    self.state = .unauthenticated
                    self.errorMessage = error.localizedDescription
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
        } catch {
            self.errorMessage = error.localizedDescription
            self.state = .unauthenticated
        }
    }
    
    @MainActor
    public func signUpWithEmail(email: String, password: String) async {
        self.state = .loading
        do {
            let user = try await authService.signUpWithEmail(email: email, password: password)
            // No cadastro por e-mail, o usuário também não tem member profile ainda.
            self.state = .authenticated(user, nil)
        } catch {
            self.errorMessage = error.localizedDescription
            self.state = .unauthenticated
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
        } catch {
            self.errorMessage = error.localizedDescription
            self.state = .authenticated(user, member)
        }
    }
    
    @MainActor
    public func signOut() async {
        self.state = .loading
        do {
            try await authService.signOut()
            self.state = .unauthenticated
        } catch {
            self.errorMessage = error.localizedDescription
            self.state = .unauthenticated
        }
    }
}
