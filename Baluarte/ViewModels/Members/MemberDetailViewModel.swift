import Foundation
import SwiftUI

@Observable
@MainActor
public final class MemberDetailViewModel {
    public var fullName: String
    public var role: String
    public var isActive: Bool
    public var isSenior: Bool
    public var isMason: Bool
    public var cid: String
    public var birthdate: Date
    
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let memberService: MemberServiceProtocol
    private let membershipService: MembershipServiceProtocol
    private var member: Member
    
    public var roles: [String] {
        ChapterRole.roles(isSenior: isSenior, isMason: isMason)
    }
    
    /// Só cadastros feitos à mão podem ser apagados — é o mesmo limite que a policy
    /// `cm_delete_admin` impõe no banco, trazido para a tela para não oferecer um
    /// botão que só falharia no servidor.
    public var canDelete: Bool { !member.hasAccount }

    public var hasAccount: Bool { member.hasAccount }

    public private(set) var accessLevel: AccessLevel

    /// O Fundador não é promovido, é transferido — assim existe exatamente um caminho
    /// para esse papel, e ele passa por uma confirmação explícita.
    public var canChangeAccessLevel: Bool { member.hasAccount && accessLevel != .owner }

    public var canReceiveOwnership: Bool { member.hasAccount && accessLevel != .owner }

    @MainActor
    public func setAccessLevel(_ level: AccessLevel) async -> Bool {
        guard level != accessLevel else { return true }

        let previous = accessLevel
        accessLevel = level
        isLoading = true
        errorMessage = nil

        do {
            try await membershipService.setAccessLevel(membershipId: member.id, level: level)
            isLoading = false
            return true
        } catch {
            accessLevel = previous
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }

    @MainActor
    public func transferOwnership() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await membershipService.transferOwnership(toMembershipId: member.id)
            accessLevel = .owner
            isLoading = false
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }

    public var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (isActive || isSenior || isMason) &&
        !(isActive && (isSenior || isMason))
    }
    
    public var hasChanges: Bool {
        member.fullName != fullName ||
        (member.role ?? "Membro") != role ||
        member.isActive != isActive ||
        member.isSenior != isSenior ||
        member.isMason != isMason ||
        (member.cid ?? "") != cid ||
        (member.birthdate ?? Date()) != birthdate
    }
    
    public func updateRoleIfNeeded() {
        if !roles.contains(role) {
            role = roles.first ?? ChapterRole.member
        }
    }
    
    public init(
        member: Member,
        memberService: MemberServiceProtocol = Services.member,
        membershipService: MembershipServiceProtocol = Services.membership
    ) {
        self.member = member
        self.memberService = memberService
        self.membershipService = membershipService
        self.accessLevel = member.level

        self.fullName = member.fullName
        self.role = member.role ?? "Membro"
        self.isActive = member.isActive
        self.isSenior = member.isSenior
        self.isMason = member.isMason
        self.cid = member.cid ?? ""
        self.birthdate = member.birthdate ?? Date()
    }
    
    public func saveChanges() async -> Bool {
        guard isValid && hasChanges else { return false }
        
        isLoading = true
        errorMessage = nil
        
        var updatedMember = member
        updatedMember.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedMember.role = role == "Membro" ? nil : role
        updatedMember.isActive = isActive
        updatedMember.isSenior = isSenior
        updatedMember.isMason = isMason
        updatedMember.cid = cid.isEmpty ? nil : cid
        updatedMember.birthdate = birthdate
        
        do {
            try await memberService.updateMember(updatedMember)
            self.member = updatedMember
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }
    
    public func deleteMember() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await memberService.deleteMember(memberId: member.id)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }
}
