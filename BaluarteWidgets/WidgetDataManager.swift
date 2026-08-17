import Foundation
import Security

struct WidgetDataManager {
    static let shared = WidgetDataManager()

    private let baseURL = SupabaseSecrets.projectURL
    private let apiKey = SupabaseSecrets.anonKey
    private let keychainService = "com.kowa.baluarte.supabase"
    private let appGroup = "group.com.kowa.baluarte"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    /// The chapter-scoped actor id. Task ownership and attendance are recorded against
    /// the membership, not the account.
    private var activeMembershipId: String? {
        sharedDefaults?.string(forKey: "currentMembershipId")
    }

    private var activeChapterId: String? {
        sharedDefaults?.string(forKey: "currentChapterId")
    }

    /// O que o widget escolheu, ou o Capítulo aberto no app quando não escolheu nada.
    /// Os dois ids andam juntos: pegar o Capítulo de um e o vínculo do outro mostraria
    /// as tarefas de ninguém.
    func resolve(membershipId: String?) -> (chapterId: String, membershipId: String)? {
        guard let membershipId else {
            guard let chapterId = activeChapterId, let membership = activeMembershipId else { return nil }
            return (chapterId, membership)
        }

        guard let chapter = sharedChapters().first(where: { $0.membershipId.uuidString == membershipId })
        else {
            // O vínculo escolhido sumiu — a pessoa saiu daquele Capítulo. Cair no ativo
            // é melhor do que o widget parar de funcionar até alguém reconfigurá-lo.
            guard let chapterId = activeChapterId, let membership = activeMembershipId else { return nil }
            return (chapterId, membership)
        }

        return (chapter.chapterId.uuidString, chapter.membershipId.uuidString)
    }

    private func sharedChapters() -> [WidgetChapter] {
        guard let data = sharedDefaults?.data(forKey: "widgetChapters") else { return [] }
        return (try? JSONDecoder().decode([WidgetChapter].self, from: data)) ?? []
    }

    // MARK: - Keychain

    private func keychainRead(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess, let data = dataTypeRef as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func keychainWrite(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    // MARK: - Token

    private struct RefreshResponse: Decodable {
        let access_token: String
        let refresh_token: String
    }

    /// Reads the `exp` claim without verifying the signature — the server is the one
    /// that validates; this only decides when to refresh preemptively.
    private func expiry(of jwt: String) -> Date? {
        let segments = jwt.split(separator: ".")
        guard segments.count > 1 else { return nil }

        var payload = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }

        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else { return nil }

        return Date(timeIntervalSince1970: exp)
    }

    private func refreshSession() async throws -> String {
        guard let refreshToken = keychainRead(account: "refreshToken") else {
            throw WidgetError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=refresh_token") else {
            throw WidgetError.notAuthenticated
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw WidgetError.notAuthenticated
        }

        let refreshed = try JSONDecoder().decode(RefreshResponse.self, from: data)
        keychainWrite(refreshed.access_token, account: "accessToken")
        // Supabase rotates refresh tokens, so the new one has to be persisted or the
        // next refresh fails.
        keychainWrite(refreshed.refresh_token, account: "refreshToken")
        return refreshed.access_token
    }

    private func validAccessToken() async throws -> String {
        guard let token = keychainRead(account: "accessToken") else {
            throw WidgetError.notAuthenticated
        }

        if let expiry = expiry(of: token), expiry.timeIntervalSinceNow > 60 {
            return token
        }

        return try await refreshSession()
    }

    /// There is deliberately no anon-key fallback. With RLS scoped to `authenticated`,
    /// an anonymous read returns `200 OK` with an empty array rather than an error —
    /// which would sail past the status check and overwrite a good cache with nothing.
    private func authorizedHeaders() async throws -> [String: String] {
        let token = try await validAccessToken()
        return [
            "apikey": apiKey,
            "Content-Type": "application/json",
            "Authorization": "Bearer \(token)"
        ]
    }

    enum WidgetError: LocalizedError {
        case notAuthenticated
        case noChapter
        /// A recusa do servidor, já traduzida. Sem este caso todo 403 do PostgREST
        /// chegava à pessoa como `POST Failed: 403`.
        case refused(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return String(localized: "Sessão expirada. Abra o app para entrar novamente.")
            case .noChapter:
                return String(localized: "Nenhum Capítulo selecionado.")
            case let .refused(message):
                return message
            }
        }
    }

    /// O envelope de erro do PostgREST. `hint` é o que interessa: o servidor não sabe o
    /// idioma de quem chamou, então cada `raise` carrega `baluarte.<chave>` e a
    /// tradução acontece no cliente — a mesma regra que vale no app, com o mesmo
    /// `ServerMessage`.
    private struct ServerFailure: Decodable {
        let message: String?
        let hint: String?
        let code: String?
    }

    /// Traduz o corpo da recusa. A ordem é a mesma de `AppError.from`: o hint antes do
    /// código, porque um 42501 que nomeia o motivo real diz mais do que "sem permissão".
    private func refusal(status: Int, body: Data) -> WidgetError {
        let failure = try? JSONDecoder().decode(ServerFailure.self, from: body)

        if let message = ServerMessage.localized(hint: failure?.hint) {
            return .refused(message)
        }

        if status == 401 {
            return .notAuthenticated
        }

        if status == 403 {
            return .refused(String(localized: "Você não tem permissão para realizar esta ação."))
        }

        // A frase do servidor é portuguesa e escrita para o log, mas dizer "não foi
        // possível concluir" quando existe um motivo nomeado é pior do que mostrá-lo.
        if let message = failure?.message, !message.isEmpty, failure?.code == "23514" {
            return .refused(message)
        }

        return .refused(String(localized: "Não foi possível concluir. Tente de novo em instantes."))
    }

    // MARK: - Cache
    //
    // Keyed by chapter (and membership, for tasks) so switching or leaving a chapter
    // cannot leave the previous chapter's data readable on the Home Screen.

    private func cachedEventsKey(_ chapterId: String) -> String {
        "widgetCachedEvents_\(chapterId)"
    }

    private func cachedTasksKey(_ chapterId: String, _ membershipId: String) -> String {
        "widgetCachedTasks_\(chapterId)_\(membershipId)"
    }

    private func getCacheEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func getCacheDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func cacheEvents(_ events: [Event], chapterId: String) {
        guard let data = try? getCacheEncoder().encode(events) else { return }
        sharedDefaults?.set(data, forKey: cachedEventsKey(chapterId))
    }

    func cachedEvents(membershipId: String?) -> [Event]? {
        guard let resolved = resolve(membershipId: membershipId),
              let data = sharedDefaults?.data(forKey: cachedEventsKey(resolved.chapterId)) else { return nil }
        return try? getCacheDecoder().decode([Event].self, from: data)
    }

    private func cacheTasks(_ tasks: [ChapterTask], chapterId: String, membershipId: String) {
        guard let data = try? getCacheEncoder().encode(tasks) else { return }
        sharedDefaults?.set(data, forKey: cachedTasksKey(chapterId, membershipId))
    }

    func cachedTasks(membershipId: String?) -> [ChapterTask]? {
        guard let resolved = resolve(membershipId: membershipId),
              let data = sharedDefaults?.data(forKey: cachedTasksKey(resolved.chapterId, resolved.membershipId))
        else { return nil }
        return try? getCacheDecoder().decode([ChapterTask].self, from: data)
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

    // MARK: - Requests

    private func get(path: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.allHTTPHeaderFields = try await authorizedHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw refusal(status: (response as? HTTPURLResponse)?.statusCode ?? -1, body: data)
        }
        return data
    }

    private func send(method: String, path: String, body: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = try await authorizedHeaders()
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // O corpo é lido mesmo quando não se usa a resposta: é ele que carrega o motivo
        // da recusa, e descartá-lo era o que transformava uma regra de negócio nomeada
        // em `PATCH Failed: 400`.
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw refusal(status: (response as? HTTPURLResponse)?.statusCode ?? -1, body: data)
        }
    }

    func fetchUpcomingEvents(membershipId: String? = nil) async throws -> [Event] {
        guard let resolved = resolve(membershipId: membershipId) else { throw WidgetError.noChapter }

        let data = try await get(path: "/rest/v1/event?chapter_id=eq.\(resolved.chapterId)&select=*")

        var events = try getSupabaseDecoder().decode([Event].self, from: data)
        let today = Calendar.current.startOfDay(for: Date())
        events = events.filter { Calendar.current.startOfDay(for: $0.scheduledDate) >= today }
        events.sort { $0.scheduledDate < $1.scheduledDate }

        cacheEvents(events, chapterId: resolved.chapterId)
        return events
    }

    func fetchPendingTasks(membershipId: String? = nil) async throws -> [ChapterTask] {
        guard let resolved = resolve(membershipId: membershipId) else { throw WidgetError.noChapter }

        let data = try await get(path: "/rest/v1/task?chapter_id=eq.\(resolved.chapterId)&select=*")
        let allTasks = try getSupabaseDecoder().decode([ChapterTask].self, from: data)

        let mine = resolved.membershipId.lowercased()
        let myTasks = allTasks.filter { task in
            !task.isCompleted &&
            (task.assigneeId?.uuidString.lowercased() == mine ||
             task.creatorId.uuidString.lowercased() == mine)
        }

        cacheTasks(myTasks, chapterId: resolved.chapterId, membershipId: resolved.membershipId)
        return myTasks
    }

    /// Attendance is written by `set_event_attendance`, which derives the membership
    /// from the caller's JWT. A plain PATCH here could rewrite the whole array.
    func confirmAttendance(eventId: String, membershipId: String? = nil) async throws {
        guard let resolved = resolve(membershipId: membershipId),
              let membershipUUID = UUID(uuidString: resolved.membershipId) else {
            throw WidgetError.notAuthenticated
        }

        let data = try await get(path: "/rest/v1/event?id=eq.\(eventId)&select=*")
        let events = try getSupabaseDecoder().decode([Event].self, from: data)
        // Sob RLS, um evento que a pessoa não pode ler devolve coleção vazia e não erro.
        // Sair calado aqui era indistinguível de ter dado certo.
        guard let event = events.first else {
            throw WidgetError.refused(String(localized: "Evento não encontrado."))
        }

        let isConfirmed = event.confirmedAttendees?.contains(membershipUUID) ?? false

        try await send(
            method: "POST",
            path: "/rest/v1/rpc/set_event_attendance",
            body: ["p_event_id": eventId, "p_confirmed": !isConfirmed]
        )
    }

    func toggleTaskCompletion(taskId: String) async throws {
        let data = try await get(path: "/rest/v1/task?id=eq.\(taskId)&select=*")
        let tasks = try getSupabaseDecoder().decode([ChapterTask].self, from: data)
        guard let task = tasks.first else {
            throw WidgetError.refused(String(localized: "Tarefa não encontrada."))
        }

        try await send(
            method: "PATCH",
            path: "/rest/v1/task?id=eq.\(taskId)",
            body: ["is_completed": !task.isCompleted]
        )
    }
}
