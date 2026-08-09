import Testing
import Foundation
@testable import Baluarte

@Suite("PermissionSet Tests")
struct PermissionSetTests {

    private static let contentPermissions: [Permission] = [
        .manageEvents, .manageGoals, .manageCommittees,
        .manageRoster, .reviewJoinRequests, .manageInvites
    ]

    private static let ownerPermissions: [Permission] = [.manageAdmins, .transferOwnership]

    @Test("Member can do nothing beyond reading and their own tasks")
    func testMemberDeniedEverything() {
        let permissions = PermissionSet(accessLevel: .member, isPlatformAdmin: false)

        for permission in Permission.allCases {
            #expect(permissions.can(permission) == false)
        }
    }

    @Test("Admin manages chapter content but not other admins")
    func testAdminScope() {
        let permissions = PermissionSet(accessLevel: .admin, isPlatformAdmin: false)

        for permission in Self.contentPermissions {
            #expect(permissions.can(permission) == true)
        }
        for permission in Self.ownerPermissions {
            #expect(permissions.can(permission) == false)
        }
        #expect(permissions.can(.reviewChapterBootstrap) == false)
    }

    @Test("Owner manages content and admins, but is not a platform admin")
    func testOwnerScope() {
        let permissions = PermissionSet(accessLevel: .owner, isPlatformAdmin: false)

        for permission in Self.contentPermissions {
            #expect(permissions.can(permission) == true)
        }
        for permission in Self.ownerPermissions {
            #expect(permissions.can(permission) == true)
        }
        #expect(permissions.can(.reviewChapterBootstrap) == false)
    }

    @Test("Platform admin reviews bootstrap requests without chapter powers")
    func testPlatformAdminIsOrthogonal() {
        let permissions = PermissionSet(accessLevel: .member, isPlatformAdmin: true)

        #expect(permissions.can(.reviewChapterBootstrap) == true)
        for permission in Self.contentPermissions {
            #expect(permissions.can(permission) == false)
        }
        for permission in Self.ownerPermissions {
            #expect(permissions.can(permission) == false)
        }
    }

    @Test("none grants nothing")
    func testNoneIsEmpty() {
        for permission in Permission.allCases {
            #expect(PermissionSet.none.can(permission) == false)
        }
    }

    @Test("Access levels are ordered member < admin < owner")
    func testAccessLevelOrdering() {
        #expect(AccessLevel.member < AccessLevel.admin)
        #expect(AccessLevel.admin < AccessLevel.owner)
        #expect(AccessLevel.owner > AccessLevel.member)
    }

    @Test("Unknown or legacy access level strings fall back to member")
    func testLegacyAccessLevelFallback() {
        #expect(AccessLevel(rawValueOrMember: "Membro") == .member)
        #expect(AccessLevel(rawValueOrMember: nil) == .member)
        #expect(AccessLevel(rawValueOrMember: "gerente") == .member)
        #expect(AccessLevel(rawValueOrMember: "ADMIN") == .admin)
        #expect(AccessLevel(rawValueOrMember: "owner") == .owner)
    }
}
