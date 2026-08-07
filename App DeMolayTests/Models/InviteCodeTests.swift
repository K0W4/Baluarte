import Testing
import Foundation
@testable import App_DeMolay

@Suite("Invite code and deep link")
struct InviteCodeTests {

    @Test("Normalising strips separators, spaces and case")
    func testNormalize() {
        #expect(InviteCode.normalize("4k7q-x2mn") == "4K7QX2MN")
        #expect(InviteCode.normalize(" 4K7Q X2MN ") == "4K7QX2MN")
        #expect(InviteCode.normalize("4K7Q–X2MN") == "4K7QX2MN")
    }

    @Test("Characters outside the alphabet are dropped, not silently mapped")
    func testAmbiguousCharactersDropped() {
        // I, L, O, U, 0 and 1 are not in the alphabet precisely because they are
        // misheard. Dropping them keeps a typo a typo instead of turning it into a
        // different, valid code.
        #expect(InviteCode.normalize("IL0U1O") == "")
        #expect(InviteCode.normalize("4K7QIX2MN") == "4K7QX2MN")
    }

    @Test("Formatting splits into two readable halves")
    func testFormat() {
        #expect(InviteCode.format("4K7QX2MN") == "4K7Q-X2MN")
        #expect(InviteCode.format("4k7qx2mn") == "4K7Q-X2MN")
        #expect(InviteCode.format("4K7") == "4K7")
    }

    @Test("Completeness is measured on the normalised code")
    func testIsComplete() {
        #expect(InviteCode.isComplete("4K7Q-X2MN") == true)
        #expect(InviteCode.isComplete("4K7QX2M") == false)
        #expect(InviteCode.isComplete("4K7QX2MNP") == false)
    }

    @Test("Invite deep links parse in the shapes messaging apps produce")
    func testDeepLinkParsing() {
        #expect(DeepLink(url: URL(string: "baluarte://invite/4K7QX2MN")!) == .invite(code: "4K7QX2MN"))
        #expect(DeepLink(url: URL(string: "baluarte:///invite/4K7QX2MN")!) == .invite(code: "4K7QX2MN"))
        #expect(DeepLink(url: URL(string: "BALUARTE://INVITE/4k7q-x2mn")!) == .invite(code: "4K7QX2MN"))
    }

    @Test("Anything that is not a complete invite link is rejected")
    func testDeepLinkRejection() {
        #expect(DeepLink(url: URL(string: "https://example.com/invite/4K7QX2MN")!) == nil)
        #expect(DeepLink(url: URL(string: "baluarte://invite")!) == nil)
        #expect(DeepLink(url: URL(string: "baluarte://invite/SHORT")!) == nil)
        #expect(DeepLink(url: URL(string: "baluarte://chapter/4K7QX2MN")!) == nil)
    }

    @Test("Generated links round-trip back to the same code")
    func testDeepLinkRoundTrip() {
        let url = DeepLink.inviteURL(code: "4k7q-x2mn")
        #expect(url != nil)
        #expect(DeepLink(url: url!) == .invite(code: "4K7QX2MN"))
    }

    @Test("Invite usability reflects revocation, expiry and exhaustion")
    func testUsability() {
        let base = ChapterInvite(id: UUID(), chapterId: UUID(), code: "4K7QX2MN", createdBy: UUID(), createdAt: Date())
        #expect(base.isUsable == true)

        var revoked = base
        revoked.revokedAt = Date()
        #expect(revoked.isUsable == false)

        var expired = base
        expired.expiresAt = Date().addingTimeInterval(-60)
        #expect(expired.isUsable == false)

        var exhausted = base
        exhausted.maxUses = 5
        exhausted.usesCount = 5
        #expect(exhausted.isUsable == false)

        var stillOpen = base
        stillOpen.maxUses = 5
        stillOpen.usesCount = 4
        stillOpen.expiresAt = Date().addingTimeInterval(3600)
        #expect(stillOpen.isUsable == true)
    }
}
