import Foundation
import Supabase

public final class SupabasePushService: PushServiceProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    public init() {}

    private struct TokenRow: Encodable {
        let token: String
        let member_id: UUID
        let last_seen_at: String
    }

    /// Falha em silêncio de propósito: não conseguir registrar o aparelho não impede
    /// ninguém de usar o app, e uma mensagem sobre isso seria sobre uma coisa que a
    /// pessoa não pediu nem pode resolver.
    public func register(token: String) async {
        guard let memberId = client.auth.currentUser?.id else { return }
        do {
            try await client
                .from("device_token")
                .upsert(TokenRow(
                    token: token,
                    member_id: memberId,
                    last_seen_at: ISO8601DateFormatter().string(from: Date())
                ), onConflict: "token")
                .execute()
        } catch {
            print("Push token registration failed: \(error)")
        }
    }

    public func unregister(token: String) async {
        do {
            try await client.from("device_token").delete().eq("token", value: token).execute()
        } catch {
            print("Push token removal failed: \(error)")
        }
    }
}
