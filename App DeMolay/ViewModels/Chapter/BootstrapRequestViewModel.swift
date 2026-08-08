import Foundation
import UIKit

@Observable
@MainActor
public final class BootstrapRequestViewModel {
    public var role: String = ""
    public var message: String = ""
    public var proofImage: UIImage?

    public var isSending = false
    public var errorMessage: String?

    private let joinRequestService: JoinRequestServiceProtocol
    private let chapter: Chapter

    public init(chapter: Chapter, joinRequestService: JoinRequestServiceProtocol = Services.joinRequest) {
        self.chapter = chapter
        self.joinRequestService = joinRequestService
    }

    public var isValid: Bool {
        !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && proofImage != nil
            && !isSending
    }

    /// O comprovante costuma vir da câmera em vários megabytes. Reduzir aqui evita
    /// upload longo em rede ruim e mantém o arquivo dentro do limite do bucket.
    func compressedProof(from image: UIImage, maxDimension: CGFloat = 1600) -> Data? {
        let largestSide = max(image.size.width, image.size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1

        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        // Escala 1 explícita: o padrão é a escala da tela, o que produziria três vezes
        // mais pixels do que o limite que acabamos de calcular.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }

        return resized.jpegData(compressionQuality: 0.75)
    }

    public func submit(memberId: UUID, cid: String?) async -> Bool {
        guard isValid, let proofImage else { return false }

        isSending = true
        errorMessage = nil

        guard let imageData = compressedProof(from: proofImage) else {
            errorMessage = "Não foi possível preparar a imagem. Tente escolher outra foto."
            isSending = false
            return false
        }

        do {
            let path = try await joinRequestService.uploadProof(memberId: memberId, imageData: imageData)

            let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
            let composed = trimmedMessage.isEmpty
                ? "Cargo: \(trimmedRole)"
                : "Cargo: \(trimmedRole)\n\n\(trimmedMessage)"

            _ = try await joinRequestService.createBootstrapRequest(
                chapterId: chapter.id,
                memberId: memberId,
                message: composed,
                cid: cid,
                proofPath: path
            )

            isSending = false
            return true
        } catch {
            if error is CancellationError { isSending = false; return false }
            errorMessage = AppError.from(error).userMessage
            isSending = false
            return false
        }
    }

    /// Atalho humano depois do envio: o número fica no Info.plist, nunca embutido no código.
    public func supportURL(requestReference: String) -> URL? {
        guard let number = Bundle.main.object(forInfoDictionaryKey: "SupportWhatsApp") as? String,
              !number.isEmpty else { return nil }

        let text = """
        Olá! Solicitei ser o primeiro administrador do \(chapter.name) nº \(chapter.number) no Baluarte. Referência: \(requestReference)
        """

        var components = URLComponents(string: "https://wa.me/\(number)")
        components?.queryItems = [URLQueryItem(name: "text", value: text)]
        return components?.url
    }
}
