import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("MemberDetailViewModel Tests")
struct MemberDetailViewModelTests {
    
    let sampleMember = Member(
        id: UUID(),
        chapterId: UUID(),
        fullName: "John Doe",
        role: "Membro",
        isActive: true,
        isSenior: false,
        isMason: false,
        accessLevel: "Admin",
        birthdate: Date(),
        cid: "12345",
        createdAt: Date()
    )
    
    @Test("Initialization populates fields correctly")
    func testInitialization() {
        let viewModel = MemberDetailViewModel(member: sampleMember)
        
        #expect(viewModel.fullName == "John Doe")
        #expect(viewModel.role == "Membro")
        #expect(viewModel.isActive == true)
        #expect(viewModel.hasChanges == false)
        #expect(viewModel.isValid == true)
    }
    
    @Test("hasChanges works correctly")
    func testHasChanges() {
        let viewModel = MemberDetailViewModel(member: sampleMember)
        
        viewModel.fullName = "John Doe 2"
        #expect(viewModel.hasChanges == true)
    }
    
    @Test("Validation logic works correctly")
    func testValidation() {
        let viewModel = MemberDetailViewModel(member: sampleMember)
        
        viewModel.fullName = "   "
        #expect(viewModel.isValid == false)
        
        viewModel.fullName = "Valid"
        
        viewModel.isActive = true
        viewModel.isSenior = true
        #expect(viewModel.isValid == false)
        
        viewModel.isActive = false
        viewModel.isSenior = false
        viewModel.isMason = false
        #expect(viewModel.isValid == false)
    }
    
    @Test("Role lists update correctly based on member type")
    func testRolesLogic() {
        let viewModel = MemberDetailViewModel(member: sampleMember)
        
        #expect(viewModel.roles.contains("Mestre Conselheiro") == true)
        
        viewModel.isMason = true
        #expect(viewModel.roles.contains("Mestre Conselheiro") == false)
        #expect(viewModel.roles.contains("Presidente do Conselho") == true)
        
        viewModel.isMason = false
        viewModel.isSenior = true
        #expect(viewModel.roles.contains("Membro") == true)
        #expect(viewModel.roles.contains("Consultor") == true)
    }
    
    @Test("updateRoleIfNeeded fixes invalid role")
    func testUpdateRoleIfNeeded() {
        let viewModel = MemberDetailViewModel(member: sampleMember)
        viewModel.role = "Mestre Conselheiro" // valid initially
        
        viewModel.isMason = true // Mason cannot be MC
        viewModel.updateRoleIfNeeded()
        
        #expect(viewModel.role == "Membro") // defaults to Membro
    }
    
    @Test("saveChanges succeeds and updates internal member")
    func testSaveChangesSuccess() async {
        let mockService = TestMockMemberService()
        let viewModel = MemberDetailViewModel(member: sampleMember, memberService: mockService)
        
        viewModel.fullName = "New Name"
        let result = await viewModel.saveChanges()
        
        #expect(result == true)
        #expect(mockService.updateMemberCallCount == 1)
        #expect(viewModel.hasChanges == false)
    }
    
    @Test("saveChanges fails and sets error")
    func testSaveChangesFailure() async {
        let mockService = TestMockMemberService()
        mockService.shouldThrowError = true
        let viewModel = MemberDetailViewModel(member: sampleMember, memberService: mockService)
        
        viewModel.fullName = "New Name"
        let result = await viewModel.saveChanges()
        
        #expect(result == false)
        #expect(viewModel.errorMessage != nil)
    }
    
    @Test("deleteMember succeeds")
    func testDeleteMemberSuccess() async {
        let mockService = TestMockMemberService()
        let viewModel = MemberDetailViewModel(member: sampleMember, memberService: mockService)
        
        let result = await viewModel.deleteMember()
        
        #expect(result == true)
        #expect(mockService.deleteMemberCallCount == 1)
    }
}
