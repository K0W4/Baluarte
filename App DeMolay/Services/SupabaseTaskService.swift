import Foundation
import Supabase
import WidgetKit

public final class SupabaseTaskService: BaseSupabaseService<ChapterTask>, TaskServiceProtocol {
    
    public init() {
        super.init(tableName: "task")
    }
    
    public func fetchTasks(forChapter chapterId: UUID) async throws -> [ChapterTask] {
        try await fetchAll(chapterId: chapterId)
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
        WidgetManager.shared.reloadTimelines()
    }
    
    public func deleteTask(taskId: UUID) async throws {
        try await delete(id: taskId)
    }
    
    public func createTask(_ task: ChapterTask) async throws {
        try await create(task)
    }
}
