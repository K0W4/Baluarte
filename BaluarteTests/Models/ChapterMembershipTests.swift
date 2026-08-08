import Testing
import Foundation
@testable import Baluarte

@Suite("ChapterMembership Tests")
struct ChapterMembershipTests {

    @Test("ChapterMembership JSON parsing maps CodingKeys correctly")
    func testMembershipDecoding() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "chapter_id": "123e4567-e89b-12d3-a456-426614174001",
            "member_id": "123e4567-e89b-12d3-a456-426614174002",
            "full_name": "João da Silva",
            "category": "senior",
            "role": "Consultor",
            "cid": "1234567",
            "birthdate": "2001-05-12",
            "access_level": "admin",
            "status": "active",
            "joined_at": "2024-11-01T10:00:00Z",
            "approved_by": "123e4567-e89b-12d3-a456-426614174003",
            "created_at": "2024-11-01T10:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let membership = try decoder.decode(ChapterMembership.self, from: Data(json.utf8))

        #expect(membership.chapterId.uuidString == "123E4567-E89B-12D3-A456-426614174001")
        #expect(membership.memberId?.uuidString == "123E4567-E89B-12D3-A456-426614174002")
        #expect(membership.fullName == "João da Silva")
        #expect(membership.category == .senior)
        #expect(membership.accessLevel == .admin)
        #expect(membership.status == .active)
        #expect(membership.cid == "1234567")
        #expect(membership.birthdate != nil)
    }

    @Test("An accountless roster entry decodes with a null member_id")
    func testAccountlessMembershipDecoding() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "chapter_id": "123e4567-e89b-12d3-a456-426614174001",
            "member_id": null,
            "full_name": "Pedro Sem Conta",
            "category": "ativo",
            "role": null,
            "cid": null,
            "birthdate": null,
            "access_level": "member",
            "status": "active",
            "joined_at": null,
            "approved_by": null,
            "created_at": "2024-11-01T10:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let membership = try decoder.decode(ChapterMembership.self, from: Data(json.utf8))

        #expect(membership.memberId == nil)
        #expect(membership.category == .ativo)
        #expect(membership.accessLevel == .member)
        #expect(membership.birthdate == nil)
    }

    @Test("UserProfile JSON parsing maps CodingKeys correctly")
    func testUserProfileDecoding() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "full_name": "João da Silva",
            "cid": "1234567",
            "birthdate": "2001-05-12",
            "active_chapter_id": "123e4567-e89b-12d3-a456-426614174001",
            "is_platform_admin": true,
            "created_at": "2024-11-01T10:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = try decoder.decode(UserProfile.self, from: Data(json.utf8))

        #expect(profile.fullName == "João da Silva")
        #expect(profile.activeChapterId?.uuidString == "123E4567-E89B-12D3-A456-426614174001")
        #expect(profile.isPlatformAdmin == true)
    }

    @Test("The three status toggles collapse into one category")
    func testCategoryFromToggles() {
        #expect(MembershipCategory(isActive: true, isSenior: false, isMason: false) == .ativo)
        #expect(MembershipCategory(isActive: false, isSenior: true, isMason: false) == .senior)
        #expect(MembershipCategory(isActive: false, isSenior: false, isMason: true) == .macom)
        // Mason wins over senior, matching the roster form's own precedence.
        #expect(MembershipCategory(isActive: false, isSenior: true, isMason: true) == .macom)
    }
}
