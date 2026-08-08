import Foundation

public enum ChapterStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case active
    case dormant
    case pendingReview = "pending_review"

    public var displayName: String {
        switch self {
        case .active: return "Ativo"
        case .dormant: return "Dormente"
        case .pendingReview: return "Em análise"
        }
    }
}
