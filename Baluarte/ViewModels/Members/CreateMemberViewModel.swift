import Foundation
import SwiftUI

@Observable
@MainActor
public final class CreateMemberViewModel {
    public var fullName: String = ""
    public var role: String = "Membro"
    public var isActive: Bool = true
    public var isSenior: Bool = false
    public var isMason: Bool = false
    public var cid: String = ""
    public var birthdate: Date = Date().addingTimeInterval(-86400 * 365 * 18) // 18 anos
    
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let memberService: MemberServiceProtocol
    private let chapterId: UUID
    
    public var roles: [String] {
        ChapterRole.roles(isSenior: isSenior, isMason: isMason)
    }
    
    public var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (isActive || isSenior || isMason) &&
        !(isActive && (isSenior || isMason))
    }
    
    public func updateRoleIfNeeded() {
        if !roles.contains(role) {
            role = roles.first ?? ChapterRole.member
        }
    }
    
    public init(chapterId: UUID, memberService: MemberServiceProtocol = Services.member) {
        self.memberService = memberService
        self.chapterId = chapterId
    }
    
    public func saveMember() async -> Bool {
        guard isValid else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let newMember = Member(
            id: UUID(),
            chapterId: chapterId,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role == "Membro" ? nil : role,
            isActive: isActive,
            isSenior: isSenior,
            isMason: isMason,
            accessLevel: "member",
            birthdate: birthdate,
            cid: cid.isEmpty ? nil : cid,
            createdAt: Date()
        )
        
        do {
            try await memberService.createMember(newMember)
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
