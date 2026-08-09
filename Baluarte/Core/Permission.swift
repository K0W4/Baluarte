import Foundation

public enum Permission: Hashable, Sendable, CaseIterable {
    case manageEvents
    case manageGoals
    case manageCommittees
    case manageRoster
    case reviewJoinRequests
    case manageInvites
    case manageAdmins
    case transferOwnership
    case viewAccessLog
    case reviewChapterBootstrap
}

/// What the signed-in person may do in the chapter they currently have open.
///
/// This is a UX concern only: it decides which affordances are drawn. Every gated
/// action must independently be denied by an RLS policy or by an RPC raising 42501,
/// because the anon key ships inside the app binary.
public struct PermissionSet: Hashable, Sendable {
    public let accessLevel: AccessLevel
    public let isPlatformAdmin: Bool

    public static let none = PermissionSet(accessLevel: .member, isPlatformAdmin: false)

    public init(accessLevel: AccessLevel, isPlatformAdmin: Bool) {
        self.accessLevel = accessLevel
        self.isPlatformAdmin = isPlatformAdmin
    }

    public func can(_ permission: Permission) -> Bool {
        switch permission {
        case .manageEvents, .manageGoals, .manageCommittees,
             .manageRoster, .reviewJoinRequests, .manageInvites:
            return accessLevel >= .admin
        // A auditoria fica com o Fundador, e não com todo administrador: ela conta
        // quem rebaixou quem, e isso é assunto de quem responde pelo Capítulo.
        case .manageAdmins, .transferOwnership, .viewAccessLog:
            return accessLevel == .owner
        case .reviewChapterBootstrap:
            return isPlatformAdmin
        }
    }
}
