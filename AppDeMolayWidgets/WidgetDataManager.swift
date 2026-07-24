import Foundation

// A lightweight data manager for the Widget to avoid linking the entire Supabase SDK
struct WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let baseURL = SupabaseSecrets.projectURL
    private let apiKey = SupabaseSecrets.anonKey
    private let currentUserId = Constants.testUserId.uuidString
    private let chapterId = Constants.testChapterId.uuidString
    
    private var defaultHeaders: [String: String] {
        [
            "apikey": apiKey,
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
    }
    
    private func getSupabaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // DO NOT USE .convertFromSnakeCase because Event and ChapterTask already have explicit snake_case CodingKeys
        // decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) { return date }
            
            let withoutFractions = ISO8601DateFormatter()
            if let date = withoutFractions.date(from: dateString) { return date }
            
            // Supabase fallback without timezone (timestamp without time zone)
            let fallback = DateFormatter()
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            fallback.timeZone = TimeZone(abbreviation: "UTC")
            if let date = fallback.date(from: dateString) { return date }
            
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = fallback.date(from: dateString) { return date }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return decoder
    }
    
    func fetchUpcomingEvents() async throws -> [Event] {
        // Fetch events for chapter
        let url = URL(string: "\(baseURL)/rest/v1/event?chapter_id=eq.\(chapterId)&select=*")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.allHTTPHeaderFields = defaultHeaders
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "Widget", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
        }
        
        let decoder = getSupabaseDecoder()
        
        var events = try decoder.decode([Event].self, from: data)
        let now = Date()
        events = events.filter { Calendar.current.startOfDay(for: $0.scheduledDate) >= Calendar.current.startOfDay(for: now) }
        events.sort { $0.scheduledDate < $1.scheduledDate }
        
        return events
    }
    
    func fetchPendingTasks() async throws -> [ChapterTask] {
        // Fetch tasks for the chapter
        let url = URL(string: "\(baseURL)/rest/v1/task?chapter_id=eq.\(chapterId)&select=*")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.allHTTPHeaderFields = defaultHeaders
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "Widget", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
        }
        
        let decoder = getSupabaseDecoder()
        let allTasks = try decoder.decode([ChapterTask].self, from: data)
        
        let myTasks = allTasks.filter { task in
            (!task.isCompleted) &&
            (task.assigneeId?.uuidString.lowercased() == currentUserId.lowercased() ||
             task.creatorId.uuidString.lowercased() == currentUserId.lowercased())
        }
        
        return myTasks
    }
    
    func confirmAttendance(eventId: String) async throws {
        // 1. Fetch current event attendees
        let fetchUrl = URL(string: "\(baseURL)/rest/v1/event?id=eq.\(eventId)&select=*")!
        var fetchRequest = URLRequest(url: fetchUrl)
        fetchRequest.allHTTPHeaderFields = defaultHeaders
        
        let (data, fetchResponse) = try await URLSession.shared.data(for: fetchRequest)
        guard let httpResponse = fetchResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = getSupabaseDecoder()
        
        let events = try decoder.decode([Event].self, from: data)
        guard let event = events.first else { return }
        
        var attendees = event.confirmedAttendees ?? []
        guard let userUUID = UUID(uuidString: currentUserId) else { return }
        
        if attendees.contains(userUUID) {
            attendees.removeAll { $0 == userUUID }
        } else {
            attendees.append(userUUID)
        }
            
        // 2. Update event attendees
            let updateUrl = URL(string: "\(baseURL)/rest/v1/event?id=eq.\(eventId)")!
            var updateRequest = URLRequest(url: updateUrl)
            updateRequest.httpMethod = "PATCH"
            updateRequest.allHTTPHeaderFields = defaultHeaders
            
            let payload: [String: Any] = ["confirmed_attendees": attendees.map { $0.uuidString }]
            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (_, patchResponse) = try await URLSession.shared.data(for: updateRequest)
            guard let patchHttp = patchResponse as? HTTPURLResponse, (200...299).contains(patchHttp.statusCode) else {
                let statusCode = (patchResponse as? HTTPURLResponse)?.statusCode ?? -1
                throw NSError(domain: "Widget", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "PATCH Failed: \(statusCode)"])
            }
    }
    
    func toggleTaskCompletion(taskId: String) async throws {
        // 1. Fetch current task
        let fetchUrl = URL(string: "\(baseURL)/rest/v1/task?id=eq.\(taskId)&select=*")!
        var fetchRequest = URLRequest(url: fetchUrl)
        fetchRequest.allHTTPHeaderFields = defaultHeaders
        
        let (data, fetchResponse) = try await URLSession.shared.data(for: fetchRequest)
        guard let httpResponse = fetchResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = getSupabaseDecoder()
        
        let tasks = try decoder.decode([ChapterTask].self, from: data)
        guard let task = tasks.first else { return }
        
        // 2. Toggle and update
        let updateUrl = URL(string: "\(baseURL)/rest/v1/task?id=eq.\(taskId)")!
        var updateRequest = URLRequest(url: updateUrl)
        updateRequest.httpMethod = "PATCH"
        updateRequest.allHTTPHeaderFields = defaultHeaders
        
        let payload: [String: Any] = ["is_completed": !task.isCompleted]
        updateRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, patchResponse) = try await URLSession.shared.data(for: updateRequest)
        guard let patchHttp = patchResponse as? HTTPURLResponse, (200...299).contains(patchHttp.statusCode) else {
            let statusCode = (patchResponse as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "Widget", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "PATCH Failed: \(statusCode)"])
        }
    }
}
