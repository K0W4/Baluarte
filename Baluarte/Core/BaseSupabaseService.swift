import Foundation
import Supabase
import WidgetKit

open class BaseSupabaseService<T: Codable & Identifiable> where T.ID == UUID {
    public let tableName: String
    
    public var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    public init(tableName: String) {
        self.tableName = tableName
    }
    
    open func fetchAll(chapterId: UUID) async throws -> [T] {
        try await client.from(tableName).select().eq("chapter_id", value: chapterId).execute().value
    }
    
    open func create(_ item: T) async throws {
        try await client.from(tableName).insert(item).execute()
        WidgetManager.shared.reloadTimelines()
    }
    
    open func update(_ item: T) async throws {
        try await client.from(tableName).update(item).eq("id", value: item.id).execute()
        WidgetManager.shared.reloadTimelines()
    }
    
    open func delete(id: UUID) async throws {
        try await client.from(tableName).delete().eq("id", value: id).execute()
        WidgetManager.shared.reloadTimelines()
    }
}
