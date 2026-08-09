import Foundation
import Supabase
@testable import Baluarte

/// Uma sessão de mentira, decodificada em vez de construída: `Session` e `User` são
/// `Codable` com dezenas de campos, e um inicializador memberwise no teste quebraria a
/// cada versão nova do `supabase-swift`. O JSON é o mesmo contrato que o servidor
/// cumpre, então ele envelhece junto.
enum TestSession {
    static func make(userId: UUID = UUID(), accessToken: String = "access", refreshToken: String = "refresh") throws -> Session {
        let json = """
        {
          "access_token": "\(accessToken)",
          "token_type": "bearer",
          "expires_in": 3600,
          "expires_at": 4102444800,
          "refresh_token": "\(refreshToken)",
          "user": {
            "id": "\(userId.uuidString)",
            "app_metadata": {},
            "user_metadata": {},
            "aud": "authenticated",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
            "is_anonymous": false
          }
        }
        """

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Session.self, from: Data(json.utf8))
    }
}
