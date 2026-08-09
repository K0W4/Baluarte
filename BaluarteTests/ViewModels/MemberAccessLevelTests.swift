import Testing
import Foundation
@testable import Baluarte

@MainActor
@Suite("Access level and ownership Tests")
struct MemberAccessLevelTests {

    private func member(level: String, hasAccount: Bool) -> Member {
        Member(
            id: UUID(),
            chapterId: UUID(),
            fullName: "João da Silva",
            role: nil,
            isActive: true,
            isSenior: false,
            isMason: false,
            accessLevel: level,
            createdAt: Date(),
            hasAccount: hasAccount
        )
    }

    @Test("An unclaimed roster entry has no access to adjust")
    func testUnclaimedEntryHasNoAccessControls() {
        let viewModel = MemberDetailViewModel(
            member: member(level: "member", hasAccount: false),
            memberService: TestMockMemberService(),
            membershipService: TestMockMembershipService()
        )

        #expect(viewModel.canChangeAccessLevel == false)
        #expect(viewModel.canDelete == true)
    }

    @Test("Someone with an account can be promoted but not deleted")
    func testClaimedEntry() {
        let viewModel = MemberDetailViewModel(
            member: member(level: "member", hasAccount: true),
            memberService: TestMockMemberService(),
            membershipService: TestMockMembershipService()
        )

        #expect(viewModel.canChangeAccessLevel == true)
        #expect(viewModel.canDelete == false)
    }

    @Test("The current owner is not offered a level picker — that is a transfer")
    func testOwnerIsNotPromotable() {
        let viewModel = MemberDetailViewModel(
            member: member(level: "owner", hasAccount: true),
            memberService: TestMockMemberService(),
            membershipService: TestMockMembershipService()
        )

        #expect(viewModel.canChangeAccessLevel == false)
        #expect(viewModel.canReceiveOwnership == false)
    }

    @Test("Promoting sends the chosen level")
    func testPromote() async {
        let mock = TestMockMembershipService()
        let viewModel = MemberDetailViewModel(
            member: member(level: "member", hasAccount: true),
            memberService: TestMockMemberService(),
            membershipService: mock
        )

        let ok = await viewModel.setAccessLevel(.admin)

        #expect(ok == true)
        #expect(mock.lastAccessLevel == .admin)
        #expect(viewModel.accessLevel == .admin)
    }

    @Test("A refused promotion rolls the displayed level back")
    func testPromoteRollback() async {
        let mock = TestMockMembershipService()
        mock.shouldThrowError = true
        let viewModel = MemberDetailViewModel(
            member: member(level: "member", hasAccount: true),
            memberService: TestMockMemberService(),
            membershipService: mock
        )

        let ok = await viewModel.setAccessLevel(.admin)

        #expect(ok == false)
        #expect(viewModel.accessLevel == .member)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Transferring ownership marks the target as owner")
    func testTransfer() async {
        let mock = TestMockMembershipService()
        let viewModel = MemberDetailViewModel(
            member: member(level: "admin", hasAccount: true),
            memberService: TestMockMemberService(),
            membershipService: mock
        )

        let ok = await viewModel.transferOwnership()

        #expect(ok == true)
        #expect(mock.transferOwnershipCallCount == 1)
        #expect(viewModel.accessLevel == .owner)
    }
}

@MainActor
@Suite("Roster linking on approval")
struct RosterLinkingTests {

    private func pending(name: String) -> PendingJoinRequest {
        PendingJoinRequest(
            request: JoinRequest(id: UUID(), chapterId: UUID(), memberId: UUID(), createdAt: Date()),
            applicantName: name
        )
    }

    private func rosterEntry(name: String, hasAccount: Bool) -> Member {
        Member(
            id: UUID(),
            chapterId: UUID(),
            fullName: name,
            role: nil,
            isActive: true,
            isSenior: false,
            isMason: false,
            accessLevel: "member",
            createdAt: Date(),
            hasAccount: hasAccount
        )
    }

    @Test("Only unclaimed entries are offered as link candidates")
    func testOnlyUnclaimedAreOffered() async {
        let requests = TestMockJoinRequestService()
        let members = TestMockMemberService()
        members.membersToReturn = [
            rosterEntry(name: "João da Silva", hasAccount: false),
            rosterEntry(name: "Pedro Alves", hasAccount: true)
        ]

        let viewModel = JoinRequestsViewModel(
            chapterId: UUID(),
            joinRequestService: requests,
            memberService: members
        )
        await viewModel.load()

        #expect(viewModel.unclaimedEntries.count == 1)
        #expect(viewModel.unclaimedEntries.first?.fullName == "João da Silva")
    }

    @Test("A matching name is pre-selected, ignoring accents and case")
    func testSuggestionMatchesLoosely() async {
        let requests = TestMockJoinRequestService()
        let members = TestMockMemberService()
        let entry = rosterEntry(name: "joao da silva", hasAccount: false)
        members.membersToReturn = [entry]

        let viewModel = JoinRequestsViewModel(
            chapterId: UUID(),
            joinRequestService: requests,
            memberService: members
        )
        await viewModel.load()

        let request = pending(name: "João da Silva")
        viewModel.resetForm(for: request)

        #expect(viewModel.linkedMembershipId == entry.id)
    }

    @Test("No match means no link — a new entry is created")
    func testNoSuggestionWhenNamesDiffer() async {
        let requests = TestMockJoinRequestService()
        let members = TestMockMemberService()
        members.membersToReturn = [rosterEntry(name: "Outro Nome", hasAccount: false)]

        let viewModel = JoinRequestsViewModel(
            chapterId: UUID(),
            joinRequestService: requests,
            memberService: members
        )
        await viewModel.load()
        viewModel.resetForm(for: pending(name: "João da Silva"))

        #expect(viewModel.linkedMembershipId == nil)
    }

    @Test("Approving forwards the chosen link and drops it from the candidates")
    func testApproveForwardsLink() async {
        let requests = TestMockJoinRequestService()
        let members = TestMockMemberService()
        let entry = rosterEntry(name: "João da Silva", hasAccount: false)
        members.membersToReturn = [entry]

        let request = pending(name: "João da Silva")
        requests.pendingToReturn = [request]

        let viewModel = JoinRequestsViewModel(
            chapterId: UUID(),
            joinRequestService: requests,
            memberService: members
        )
        await viewModel.load()
        viewModel.resetForm(for: request)

        let ok = await viewModel.approve(request)

        #expect(ok == true)
        #expect(requests.lastLinkedMembershipId == entry.id)
        #expect(viewModel.unclaimedEntries.isEmpty)
    }
}
