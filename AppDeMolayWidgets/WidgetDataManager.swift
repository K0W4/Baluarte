import Foundation
import Security

struct WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let baseURL = SupabaseSecrets.projectURL
    private let apiKey = SupabaseSecrets.anonKey
    private var currentUserId: String? {
        UserDefaults(suiteName: "group.com.kowa.baluarte")?.string(forKey: "currentUserId")
    }
    private var chapterId: String? {
        UserDefaults(suiteName: "group.com.kowa.baluarte")?.string(forKey: "currentChapterId")
    }
    private var accessToken: String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.kowa.baluarte.supabase",
            kSecAttrAccount as String: "accessToken",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        // Fallback para quem estiver com o app antigo, migração:
        return UserDefaults(suiteName: "group.com.kowa.baluarte")?.string(forKey: "accessToken")
    }
    
    private var defaultHeaders: [String: String] {
        var headers = [
            "apikey": apiKey,
            "Content-Type": "application/json"
        ]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        } else {
            headers["Authorization"] = "Bearer \(apiKey)"
        }
        return headers
    }
    
    private func getSupabaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) { return date }
            
            let withoutFractions = ISO8601DateFormatter()
            if let date = withoutFractions.date(from: dateString) { return date }
            
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
        guard let chapterId = self.chapterId else { return [] }
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
        guard let chapterId = self.chapterId else { return [] }
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
        
        guard let currentUserId = self.currentUserId else { return [] }
        
        let myTasks = allTasks.filter { task in
            (!task.isCompleted) &&
            (task.assigneeId?.uuidString.lowercased() == currentUserId.lowercased() ||
             task.creatorId.uuidString.lowercased() == currentUserId.lowercased())
        }
        
        return myTasks
    }
    
    func confirmAttendance(eventId: String) async throws {
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
        guard let currentUserId = self.currentUserId, let userUUID = UUID(uuidString: currentUserId) else { return }
        
        if attendees.contains(userUUID) {
            attendees.removeAll { $0 == userUUID }
        } else {
            attendees.append(userUUID)
        }
            
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
