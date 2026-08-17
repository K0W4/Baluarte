import Foundation

/// Custom URL scheme rather than a Universal Link: there is no domain and no
/// apple-app-site-association to host, and the code is always typable by hand — the
/// link is convenience, never the only way in.
public enum DeepLink: Equatable, Sendable {
    case invite(code: String)
    /// The whole URL, because the recovery tokens travel in the fragment and only
    /// the Supabase client knows how to read them.
    case passwordRecovery(url: URL)

    public static let scheme = "baluarte"

    public static let passwordRecoveryURL = URL(string: "\(scheme)://password-recovery")

    public init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme else { return nil }

        // Accepts baluarte://invite/CODE and baluarte:///invite/CODE alike, since
        // messaging apps rewrite links in ways nobody controls.
        var parts = url.pathComponents.filter { $0 != "/" }
        if let host = url.host, !host.isEmpty { parts.insert(host, at: 0) }

        if parts.first?.lowercased() == "password-recovery" {
            self = .passwordRecovery(url: url)
            return
        }

        guard parts.first?.lowercased() == "invite", parts.count >= 2 else { return nil }

        let code = InviteCode.normalize(parts[1])
        guard InviteCode.isComplete(code) else { return nil }

        self = .invite(code: code)
    }

    public static func inviteURL(code: String) -> URL? {
        URL(string: "\(scheme)://invite/\(InviteCode.normalize(code))")
    }
}
