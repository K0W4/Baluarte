import Testing
import Foundation
@testable import App_DeMolay

@MainActor
@Suite("RedeemInviteViewModel Tests")
struct RedeemInviteViewModelTests {

    @Test("Typing is formatted live and clamped to the code length")
    func testFormatInput() {
        let viewModel = RedeemInviteViewModel(inviteService: TestMockInviteService())

        viewModel.formatInput("4k7q")
        #expect(viewModel.code == "4K7Q")

        viewModel.formatInput("4k7qx2mn")
        #expect(viewModel.code == "4K7Q-X2MN")

        viewModel.formatInput("4k7qx2mnEXTRA")
        #expect(viewModel.code == "4K7Q-X2MN")
    }

    @Test("An incomplete code cannot be submitted")
    func testValidity() {
        let viewModel = RedeemInviteViewModel(inviteService: TestMockInviteService())

        viewModel.formatInput("4K7Q")
        #expect(viewModel.isValid == false)

        viewModel.formatInput("4K7QX2MN")
        #expect(viewModel.isValid == true)
    }

    @Test("The server receives the code without its separator")
    func testRedeemSendsNormalizedCode() async {
        let mock = TestMockInviteService()
        let viewModel = RedeemInviteViewModel(inviteService: mock)

        viewModel.formatInput("4k7qx2mn")
        let membership = await viewModel.redeem()

        #expect(membership != nil)
        #expect(mock.redeemCallCount == 1)
        #expect(mock.lastRedeemedCode == "4K7Q-X2MN")
    }

    @Test("A refused code surfaces the reason and returns nothing")
    func testRedeemFailure() async {
        let mock = TestMockInviteService()
        mock.shouldThrowError = true
        let viewModel = RedeemInviteViewModel(inviteService: mock)

        viewModel.formatInput("4K7QX2MN")
        let membership = await viewModel.redeem()

        #expect(membership == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("Submitting an incomplete code never reaches the network")
    func testIncompleteCodeDoesNotCallService() async {
        let mock = TestMockInviteService()
        let viewModel = RedeemInviteViewModel(inviteService: mock)

        viewModel.formatInput("4K7Q")
        let membership = await viewModel.redeem()

        #expect(membership == nil)
        #expect(mock.redeemCallCount == 0)
    }
}

@MainActor
@Suite("InviteManagementViewModel Tests")
struct InviteManagementViewModelTests {

    private func invite(usable: Bool) -> ChapterInvite {
        ChapterInvite(
            id: UUID(),
            chapterId: UUID(),
            code: "4K7QX2MN",
            revokedAt: usable ? nil : Date(),
            createdBy: UUID(),
            createdAt: Date()
        )
    }

    @Test("Active and inactive invites are separated for display")
    func testPartitioning() async {
        let mock = TestMockInviteService()
        mock.invitesToReturn = [invite(usable: true), invite(usable: false), invite(usable: true)]

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: mock)
        await viewModel.load()

        #expect(viewModel.activeInvites.count == 2)
        #expect(viewModel.inactiveInvites.count == 1)
    }

    @Test("Validity choices map to the expected expiry")
    func testValidityMapping() {
        #expect(InviteManagementViewModel.Validity.never.expiryDate == nil)
        #expect(InviteManagementViewModel.Validity.week.expiryDate != nil)
        #expect(InviteManagementViewModel.Validity.month.expiryDate != nil)

        let week = InviteManagementViewModel.Validity.week.expiryDate ?? Date()
        let month = InviteManagementViewModel.Validity.month.expiryDate ?? Date()
        #expect(week < month)
    }

    @Test("The use limit is only sent when the admin asked for one")
    func testMaxUsesOnlyWhenLimited() async {
        let mock = TestMockInviteService()
        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: mock)

        _ = await viewModel.create(createdBy: UUID())
        #expect(mock.lastCreatedMaxUses == nil)

        viewModel.limitUses = true
        viewModel.maxUses = 25
        _ = await viewModel.create(createdBy: UUID())
        #expect(mock.lastCreatedMaxUses == 25)
    }

    @Test("A failed revoke puts the invite back instead of faking success")
    func testRevokeRollsBack() async {
        let mock = TestMockInviteService()
        let target = invite(usable: true)
        mock.invitesToReturn = [target]

        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: mock)
        await viewModel.load()
        mock.shouldThrowError = true

        await viewModel.revoke(target)

        #expect(viewModel.activeInvites.count == 1)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("The shared text leads with the code and carries the link")
    func testShareText() {
        let mock = TestMockInviteService()
        let viewModel = InviteManagementViewModel(chapterId: UUID(), inviteService: mock)
        let text = viewModel.shareText(for: invite(usable: true), chapterName: "Capítulo Porto Alegre")

        #expect(text.contains("Capítulo Porto Alegre"))
        #expect(text.contains("4K7Q-X2MN"))
        #expect(text.contains("baluarte://invite/4K7QX2MN"))
    }
}
