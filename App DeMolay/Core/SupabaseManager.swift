import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()
    
    private let supabaseURL = URL(string: SupabaseSecrets.projectURL)!
    private let supabaseKey = SupabaseSecrets.anonKey
    
    public let client: SupabaseClient
    
    private init() {
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
