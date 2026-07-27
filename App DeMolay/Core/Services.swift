import Foundation

public struct Services {
    public static let event: EventServiceProtocol = SupabaseEventService()
    public static let goal: GoalServiceProtocol = SupabaseGoalService()
    public static let member: MemberServiceProtocol = SupabaseMemberService()
    public static let task: TaskServiceProtocol = SupabaseTaskService()
    public static let committee: CommitteeServiceProtocol = SupabaseCommitteeService()
    public static let chapter: ChapterServiceProtocol = ChapterService()
}
