import Testing
import Foundation
import UIKit
@testable import Baluarte

@MainActor
@Suite("Bootstrap request Tests")
struct BootstrapRequestViewModelTests {

    private func makeChapter() -> Chapter {
        Chapter(id: UUID(), name: "Capítulo Porto Alegre", number: 46, uf: "RS", city: "Porto Alegre")
    }

    private func makeImage(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.darkGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test("Both a role and a proof are required before sending")
    func testValidity() {
        let mock = TestMockJoinRequestService()
        let viewModel = BootstrapRequestViewModel(chapter: makeChapter(), joinRequestService: mock)

        #expect(viewModel.isValid == false)

        viewModel.role = "Mestre Conselheiro"
        #expect(viewModel.isValid == false)

        viewModel.proofImage = makeImage(size: CGSize(width: 100, height: 100))
        #expect(viewModel.isValid == true)

        viewModel.role = "   "
        #expect(viewModel.isValid == false)
    }

    @Test("An oversized photo is shrunk before upload")
    func testProofCompression() {
        let mock = TestMockJoinRequestService()
        let viewModel = BootstrapRequestViewModel(chapter: makeChapter(), joinRequestService: mock)

        let huge = makeImage(size: CGSize(width: 4032, height: 3024))
        let data = viewModel.compressedProof(from: huge)

        #expect(data != nil)
        // O bucket aceita 8 MB; uma foto de câmera crua passa disso com facilidade.
        #expect((data?.count ?? .max) < 8 * 1024 * 1024)

        let resized = UIImage(data: data ?? Data())
        #expect((resized?.size.width ?? 0) <= 1600)
        #expect((resized?.size.height ?? 0) <= 1600)
    }

    @Test("Submitting uploads the proof first and sends its path")
    func testSubmitOrdering() async {
        let mock = TestMockJoinRequestService()
        let viewModel = BootstrapRequestViewModel(chapter: makeChapter(), joinRequestService: mock)

        viewModel.role = "Escrivão"
        viewModel.proofImage = makeImage(size: CGSize(width: 200, height: 200))

        let ok = await viewModel.submit(memberId: UUID(), cid: "1234567")

        #expect(ok == true)
        #expect(mock.uploadProofCallCount == 1)
        #expect(mock.createBootstrapRequestCallCount == 1)
        #expect(mock.lastBootstrapProofPath?.hasSuffix(".jpg") == true)
    }

    @Test("The role always reaches the reviewer, with or without a note")
    func testRoleIsAlwaysInTheMessage() async {
        let mock = TestMockJoinRequestService()
        let viewModel = BootstrapRequestViewModel(chapter: makeChapter(), joinRequestService: mock)

        viewModel.role = "1º Conselheiro"
        viewModel.proofImage = makeImage(size: CGSize(width: 100, height: 100))
        _ = await viewModel.submit(memberId: UUID(), cid: nil)

        #expect(mock.createBootstrapRequestCallCount == 1)
    }

    @Test("A failed upload never creates a request pointing at nothing")
    func testFailedUploadDoesNotCreateRequest() async {
        let mock = TestMockJoinRequestService()
        mock.shouldThrowError = true
        let viewModel = BootstrapRequestViewModel(chapter: makeChapter(), joinRequestService: mock)

        viewModel.role = "Consultor"
        viewModel.proofImage = makeImage(size: CGSize(width: 100, height: 100))

        let ok = await viewModel.submit(memberId: UUID(), cid: nil)

        #expect(ok == false)
        #expect(mock.createBootstrapRequestCallCount == 0)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSending == false)
    }
}

@MainActor
@Suite("Bootstrap queue Tests")
struct BootstrapQueueViewModelTests {

    private func makeRequest() -> BootstrapRequest {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "chapter_id": "\(UUID().uuidString)",
            "member_id": "\(UUID().uuidString)",
            "message": "Cargo: Mestre Conselheiro",
            "cid_snapshot": "1234567",
            "proof_path": "abc/def.jpg",
            "created_at": "2026-08-08T10:00:00Z",
            "applicant_name": "João da Silva",
            "chapter_name": "Capítulo Porto Alegre",
            "chapter_number": 46,
            "chapter_uf": "RS"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // Fixture inválida faria o teste mentir; falhar aqui é o comportamento certo.
        return try! decoder.decode(BootstrapRequest.self, from: Data(json.utf8))
    }

    @Test("The queue loads and labels the chapter for the reviewer")
    func testLoad() async {
        let mock = TestMockJoinRequestService()
        mock.bootstrapToReturn = [makeRequest()]

        let viewModel = BootstrapQueueViewModel(joinRequestService: mock)
        await viewModel.load()

        #expect(viewModel.requests.count == 1)
        #expect(viewModel.requests.first?.chapterLabel == "Capítulo Porto Alegre nº 46 · RS")
    }

    @Test("Approving a founding always grants owner")
    func testApproveGrantsOwner() async {
        let mock = TestMockJoinRequestService()
        let request = makeRequest()
        mock.bootstrapToReturn = [request]

        let viewModel = BootstrapQueueViewModel(joinRequestService: mock)
        await viewModel.load()
        let ok = await viewModel.approve(request)

        #expect(ok == true)
        #expect(mock.lastApprovedAccessLevel == .owner)
        #expect(viewModel.requests.isEmpty)
    }

    @Test("A failed approval keeps the request in the queue")
    func testApproveFailureKeepsRequest() async {
        let mock = TestMockJoinRequestService()
        let request = makeRequest()
        mock.bootstrapToReturn = [request]

        let viewModel = BootstrapQueueViewModel(joinRequestService: mock)
        await viewModel.load()
        mock.shouldThrowError = true

        let ok = await viewModel.approve(request)

        #expect(ok == false)
        #expect(viewModel.requests.count == 1)
        #expect(viewModel.errorMessage != nil)
    }
}

/// O caminho do comprovante é a única string do app que um `=` de `text` no
/// Postgres compara com `auth.uid()::text`, e esse `=` distingue caso. Com o
/// `UUID.uuidString` cru — MAIÚSCULO — a policy `proof_insert_own` recusava o
/// dono da própria pasta, e fundar Capítulo terminava em 403.
@Suite("Bootstrap proof path")
struct BootstrapProofPathTests {

    @Test("The path is lowercase on both segments")
    func testPathIsLowercase() {
        let member = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F") ?? UUID()
        let file = UUID(uuidString: "2893B127-C24E-4BA0-B19F-AA15BD664D16") ?? UUID()

        let path = SupabaseJoinRequestService.proofPath(memberId: member, fileId: file)

        #expect(path == "e621e1f8-c36c-495a-93fc-0c247a3e6e5f/2893b127-c24e-4ba0-b19f-aa15bd664d16.jpg")
    }

    @Test("The first folder is the owner, which is what the policy checks")
    func testFirstFolderIsTheOwner() {
        let member = UUID()

        let path = SupabaseJoinRequestService.proofPath(memberId: member)

        #expect(path.split(separator: "/").first.map(String.init) == member.uuidString.lowercased())
    }
}
