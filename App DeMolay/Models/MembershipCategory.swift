import Foundation

public enum MembershipCategory: String, Codable, Hashable, Sendable, CaseIterable {
    case ativo
    case senior
    case macom

    public var displayName: String {
        switch self {
        case .ativo: return "Ativo"
        case .senior: return "Sênior"
        case .macom: return "Maçom"
        }
    }

    public init(isActive: Bool, isSenior: Bool, isMason: Bool) {
        if isMason {
            self = .macom
        } else if isSenior {
            self = .senior
        } else {
            self = .ativo
        }
    }

    public var isActive: Bool { self == .ativo }
    public var isSenior: Bool { self == .senior }
    public var isMason: Bool { self == .macom }
}
