import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()
    
    private let supabaseURL: URL
    private let supabaseKey = SupabaseSecrets.anonKey
    
    public let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: SupabaseSecrets.projectURL) else {
            fatalError("URL do Supabase inválida")
        }
        self.supabaseURL = url
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: .init(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
