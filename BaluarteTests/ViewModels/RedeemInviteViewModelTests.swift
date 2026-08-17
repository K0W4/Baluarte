import Testing
import Foundation
@testable import Baluarte

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
