import Foundation

public struct Services {
    public nonisolated(unsafe) static let event: EventServiceProtocol = SupabaseEventService()
    public nonisolated(unsafe) static let goal: GoalServiceProtocol = SupabaseGoalService()
    public nonisolated(unsafe) static let member: MemberServiceProtocol = SupabaseMemberService()
    public nonisolated(unsafe) static let task: TaskServiceProtocol = SupabaseTaskService()
    public nonisolated(unsafe) static let committee: CommitteeServiceProtocol = SupabaseCommitteeService()
    public nonisolated(unsafe) static let chapter: ChapterServiceProtocol = ChapterService()
    public static let intelligence: IntelligenceServiceProtocol = AppleIntelligenceService()
}
