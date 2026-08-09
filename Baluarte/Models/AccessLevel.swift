import Foundation

public enum AccessLevel: String, Codable, Hashable, Sendable, CaseIterable, Comparable {
    case member
    case admin
    case owner

    private var rank: Int {
        switch self {
        case .member: return 0
        case .admin: return 1
        case .owner: return 2
        }
    }

    public var displayName: String {
        switch self {
        case .member: return String(localized: "Membro")
        case .admin: return String(localized: "Administrador")
        case .owner: return String(localized: "Fundador")
        }
    }

    public static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool {
        lhs.rank < rhs.rank
    }

    public init(rawValueOrMember raw: String?) {
        self = AccessLevel(rawValue: raw?.lowercased() ?? "") ?? .member
    }
}
