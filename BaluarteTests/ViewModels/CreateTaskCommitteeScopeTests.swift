import Testing
import Foundation
@testable import Baluarte

@MainActor
@Suite("CreateTaskViewModel committee scope")
struct CreateTaskCommitteeScopeTests {

    private func makeCommittees(mine: UUID) -> (mine: Committee, chaired: Committee, other: Committee) {
        let chapterId = UUID()
        return (
            Committee(id: UUID(), chapterId: chapterId, name: "Sou membro",
                      chairmanId: UUID(), memberIds: [mine], createdAt: Date()),
            Committee(id: UUID(), chapterId: chapterId, name: "Sou presidente",
                      chairmanId: mine, memberIds: [], createdAt: Date()),
            Committee(id: UUID(), chapterId: chapterId, name: "Não pertenço",
                      chairmanId: UUID(), memberIds: [UUID()], createdAt: Date())
        )
    }

    @Test("A member only sees committees they belong to")
    func testMemberSeesOnlyOwnCommittees() {
        let membershipId = UUID()
        let committees = makeCommittees(mine: membershipId)

        let viewModel = CreateTaskViewModel(
            chapterId: UUID(),
            currentMembershipId: membershipId,
            accessLevel: .member
        )

        let selectable = viewModel.selectableCommittees(
            from: [committees.mine, committees.chaired, committees.other]
        )

        #expect(selectable.count == 2)
        #expect(selectable.contains { $0.id == committees.mine.id })
        #expect(selectable.contains { $0.id == committees.chaired.id })
        #expect(selectable.contains { $0.id == committees.other.id } == false)
    }

    @Test("Being the chairman counts as belonging")
    func testChairmanCounts() {
        let membershipId = UUID()
        let committees = makeCommittees(mine: membershipId)

        let viewModel = CreateTaskViewModel(
            chapterId: UUID(),
            currentMembershipId: membershipId,
            accessLevel: .member
        )

        #expect(viewModel.selectableCommittees(from: [committees.chaired]).count == 1)
    }

    @Test("Admins and owners keep the full list")
    func testAdminSeesAll() {
        let membershipId = UUID()
        let committees = makeCommittees(mine: membershipId)
        let all = [committees.mine, committees.chaired, committees.other]

        for level in [AccessLevel.admin, .owner] {
            let viewModel = CreateTaskViewModel(
                chapterId: UUID(),
                currentMembershipId: membershipId,
                accessLevel: level
            )
            #expect(viewModel.selectableCommittees(from: all).count == 3)
        }
    }

    @Test("A member belonging to nothing gets an empty picker")
    func testMemberWithNoCommittees() {
        let committees = makeCommittees(mine: UUID())

        let viewModel = CreateTaskViewModel(
            chapterId: UUID(),
            currentMembershipId: UUID(),
            accessLevel: .member
        )

        #expect(viewModel.selectableCommittees(from: [committees.mine, committees.other]).isEmpty)
    }
}
