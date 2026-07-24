import Foundation
import Supabase
import WidgetKit

public final class SupabaseTaskService: TaskServiceProtocol {
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    public init() {}
    
    public func fetchTasks(forChapter chapterId: UUID) async throws -> [ChapterTask] {
        let response: [ChapterTask] = try await client
            .from("task")
            .select()
            .eq("chapter_id", value: chapterId)
            .execute()
            .value
        
        return response
    }
    
    public func toggleTaskCompletion(taskId: UUID, isCompleted: Bool) async throws {
        struct UpdateTaskCompletion: Codable {
            let is_completed: Bool
        }
        
        try await client
            .from("task")
            .update(UpdateTaskCompletion(is_completed: isCompleted))
            .eq("id", value: taskId)
            .execute()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func deleteTask(taskId: UUID) async throws {
        try await client
            .from("task")
            .delete()
            .eq("id", value: taskId)
            .execute()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func createTask(_ task: ChapterTask) async throws {
        try await client
            .from("task")
            .insert(task)
            .execute()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
