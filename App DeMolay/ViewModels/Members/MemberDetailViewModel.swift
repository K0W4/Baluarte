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
    private var member: Member
    
    public var roles: [String] {
        if isMason {
            return ["Membro", "Consultor", "Presidente do Conselho"]
        } else if isSenior {
            return ["Membro", "Consultor"]
        } else {
            return ["Membro", "Mestre Conselheiro", "1º Conselheiro", "2º Conselheiro", "Escrivão", "Tesoureiro", "Hospitalário"]
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
            role = roles.first ?? "Membro"
        }
    }
    
    public init(member: Member, memberService: MemberServiceProtocol = Services.member) {
        self.member = member
        self.memberService = memberService
        
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
            errorMessage = "Erro ao atualizar o membro."
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
            errorMessage = "Erro ao excluir o membro."
            isLoading = false
            return false
        }
    }
}
