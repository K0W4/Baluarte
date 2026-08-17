import Foundation

public struct UserDefaultsManager: @unchecked Sendable {
    public static let shared = UserDefaultsManager()

    public static let keychainService = "com.kowa.baluarte.supabase"

    private let defaults: UserDefaults

    private init() {
        self.defaults = UserDefaults(suiteName: "group.com.kowa.baluarte") ?? .standard
    }

    private func uuid(forKey key: String) -> UUID? {
        guard let string = defaults.string(forKey: key) else { return nil }
        return UUID(uuidString: string)
    }

    public var currentChapterId: UUID? {
        get { uuid(forKey: "currentChapterId") }
        nonmutating set { defaults.set(newValue?.uuidString, forKey: "currentChapterId") }
    }

    /// The signed-in person's bond with the chapter currently open. Every chapter-scoped
    /// reference — committee members, task assignees, attendance — points at this, not
    /// at `currentUserId`.
    public var currentMembershipId: UUID? {
        get { uuid(forKey: "currentMembershipId") }
        nonmutating set { defaults.set(newValue?.uuidString, forKey: "currentMembershipId") }
    }

    public var currentUserId: UUID? {
        get { uuid(forKey: "currentUserId") }
        nonmutating set { defaults.set(newValue?.uuidString, forKey: "currentUserId") }
    }

    /// Os Capítulos entre os quais o widget pode escolher. O app group só carregava o
    /// vínculo aberto, então o widget não tinha como oferecer o outro a quem tem dupla
    /// filiação — e a lista tem de vir daqui porque o widget não fala com o Supabase
    /// para descobrir um nome.
    public var widgetChapters: [WidgetChapter] {
        get {
            guard let data = defaults.data(forKey: "widgetChapters") else { return [] }
            return (try? JSONDecoder().decode([WidgetChapter].self, from: data)) ?? []
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: "widgetChapters")
        }
    }

    public var accessToken: String? {
        get {
            KeychainHelper.shared.readString(service: Self.keychainService, account: "accessToken")
        }
        nonmutating set {
            if let newValue = newValue {
                KeychainHelper.shared.save(newValue, service: Self.keychainService, account: "accessToken")
            } else {
                KeychainHelper.shared.delete(service: Self.keychainService, account: "accessToken")
            }
        }
    }

    /// Needed by the widget, which runs in its own process and cannot ask the Supabase
    /// SDK to refresh for it.
    public var refreshToken: String? {
        get {
            KeychainHelper.shared.readString(service: Self.keychainService, account: "refreshToken")
        }
        nonmutating set {
            if let newValue = newValue {
                KeychainHelper.shared.save(newValue, service: Self.keychainService, account: "refreshToken")
            } else {
                KeychainHelper.shared.delete(service: Self.keychainService, account: "refreshToken")
            }
        }
    }

    public func clearSession() {
        currentChapterId = nil
        currentMembershipId = nil
        currentUserId = nil
        widgetChapters = []
        accessToken = nil
        refreshToken = nil
    }
}
