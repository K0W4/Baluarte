import AuthenticationServices
import CryptoKit
import Foundation

public struct AppleCredentials: Sendable {
    public let idToken: String
    public let nonce: String
    public let fullName: String?
}

public final class AppleSignInHelper {

    public static let shared = AppleSignInHelper()

    private var currentNonce: String?

    private init() {}

    // MARK: - SignInWithAppleButton

    public func prepare(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        self.currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    public func credentials(from authorization: ASAuthorization) throws -> AppleCredentials {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw NSError(domain: "AppleSignInHelper", code: 3, userInfo: [NSLocalizedDescriptionKey: "Credencial da Apple em formato inesperado."])
        }

        guard let nonce = currentNonce else {
            throw NSError(domain: "AppleSignInHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Estado inválido: resposta recebida sem uma solicitação correspondente."])
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw NSError(domain: "AppleSignInHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Não foi possível obter o token de identidade."])
        }

        var fullNameString: String? = nil
        if let fullName = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            fullNameString = formatter.string(from: fullName)
        }

        currentNonce = nil
        return AppleCredentials(idToken: idTokenString, nonce: nonce, fullName: fullNameString)
    }

    // MARK: - Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
