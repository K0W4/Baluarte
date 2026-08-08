import Testing
import Foundation
@testable import Baluarte

@MainActor
@Suite("CreateMemberViewModel Tests")
struct CreateMemberViewModelTests {
    
    @Test("Initialization sets default values")
    func testInitialization() {
        let viewModel = CreateMemberViewModel(chapterId: UUID())
        
        #expect(viewModel.fullName == "")
        #expect(viewModel.role == "Membro")
        #expect(viewModel.isActive == true)
        #expect(viewModel.isSenior == false)
        #expect(viewModel.isMason == false)
        #expect(viewModel.isValid == false)
    }
    
    @Test("Validation logic")
    func testValidation() {
        let viewModel = CreateMemberViewModel(chapterId: UUID())
        
        viewModel.fullName = "John Doe"
        #expect(viewModel.isValid == true)
        
        viewModel.isActive = true
        viewModel.isSenior = true
        #expect(viewModel.isValid == false) // Active and Senior
        
        viewModel.isActive = false
        viewModel.isSenior = false
        viewModel.isMason = false
        #expect(viewModel.isValid == false) // None selected
    }
    
    @Test("Role logic works correctly")
    func testRolesLogic() {
        let viewModel = CreateMemberViewModel(chapterId: UUID())
        
        #expect(viewModel.roles.contains("Mestre Conselheiro") == true)
        
        viewModel.isMason = true
        #expect(viewModel.roles.contains("Mestre Conselheiro") == false)
        #expect(viewModel.roles.contains("Presidente do Conselho") == true)
    }
    
    @Test("updateRoleIfNeeded fixes invalid role")
    func testUpdateRoleIfNeeded() {
        let viewModel = CreateMemberViewModel(chapterId: UUID())
        viewModel.role = "Mestre Conselheiro" // valid initially
        
        viewModel.isMason = true // Mason cannot be MC
        viewModel.updateRoleIfNeeded()
        
        #expect(viewModel.role == "Membro") // defaults to Membro
    }
    
    @Test("saveMember succeeds")
    func testSaveMemberSuccess() async {
        let mockService = TestMockMemberService()
        let viewModel = CreateMemberViewModel(chapterId: UUID(), memberService: mockService)
        
        viewModel.fullName = "John Doe"
        let result = await viewModel.saveMember()
        
        #expect(result == true)
        #expect(mockService.createMemberCallCount == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("saveMember fails and sets error")
    func testSaveMemberFailure() async {
        let mockService = TestMockMemberService()
        mockService.shouldThrowError = true
        let viewModel = CreateMemberViewModel(chapterId: UUID(), memberService: mockService)
        
        viewModel.fullName = "John Doe"
        let result = await viewModel.saveMember()
        
        #expect(result == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
}
