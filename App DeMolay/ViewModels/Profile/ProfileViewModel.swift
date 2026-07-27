import Foundation

@Observable
public final class ProfileViewModel {
    public var errorMessage: String?
    public var isLoading = false
    
    private let authService: AuthServiceProtocol
    
    public init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    @MainActor
    public func signOut() async {
        self.isLoading = true
        do {
            try await authService.signOut()
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
