import Foundation

public struct Services {
    public nonisolated(unsafe) static let event: EventServiceProtocol = SupabaseEventService()
    public nonisolated(unsafe) static let goal: GoalServiceProtocol = SupabaseGoalService()
    public nonisolated(unsafe) static let member: MemberServiceProtocol = SupabaseMemberService()
    public nonisolated(unsafe) static let profile: ProfileServiceProtocol = SupabaseProfileService()
    public nonisolated(unsafe) static let membership: MembershipServiceProtocol = SupabaseMembershipService()
    public nonisolated(unsafe) static let joinRequest: JoinRequestServiceProtocol = SupabaseJoinRequestService()
    public nonisolated(unsafe) static let invite: InviteServiceProtocol = SupabaseInviteService()
    public nonisolated(unsafe) static let task: TaskServiceProtocol = SupabaseTaskService()
    public nonisolated(unsafe) static let committee: CommitteeServiceProtocol = SupabaseCommitteeService()
    public nonisolated(unsafe) static let chapter: ChapterServiceProtocol = ChapterService()
    public nonisolated(unsafe) static let push: PushServiceProtocol = SupabasePushService()
    public nonisolated(unsafe) static let sessionStore: SessionStoreProtocol = AppGroupSessionStore()
    public static let intelligence: IntelligenceServiceProtocol = AppleIntelligenceService()
}
