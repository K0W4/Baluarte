import Foundation

public enum ChapterStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case active
    case dormant
    case pendingReview = "pending_review"

    public var displayName: String {
        switch self {
        case .active: return String(localized: "Ativo")
        case .dormant: return String(localized: "Dormente")
        case .pendingReview: return String(localized: "Em análise")
        }
    }
}
