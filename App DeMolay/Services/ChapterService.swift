import Foundation
import Supabase

public class ChapterService: ChapterServiceProtocol {
    private let client = SupabaseManager.shared.client
    
    public init() {}
    
    public func fetchChapters() async throws -> [Chapter] {
        return try await client
            .from("chapter")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    public func searchChapters(query: String) async throws -> [Chapter] {
        return try await client
            .from("chapter")
            .select()
            .ilike("name", pattern: "%\(query)%")
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    public func chapterExists(number: Int) async throws -> Bool {
        let matches: [Chapter] = try await client
            .from("chapter")
            .select()
            .eq("number", value: number)
            .limit(1)
            .execute()
            .value

        return !matches.isEmpty
    }

    public func createChapter(_ chapter: Chapter) async throws -> Chapter {
        let insertedChapter: Chapter = try await client
            .from("chapter")
            .insert(chapter)
            .select()
            .single()
            .execute()
            .value
            
        return insertedChapter
    }
}
