import Foundation

public final class AppGroupSessionStore: SessionStoreProtocol {
    public init() {}

    public func save(
        userId: UUID?, chapterId: UUID?, membershipId: UUID?,
        chapters: [WidgetChapter],
        accessToken: String, refreshToken: String
    ) {
        UserDefaultsManager.shared.currentUserId = userId
        UserDefaultsManager.shared.currentChapterId = chapterId
        UserDefaultsManager.shared.currentMembershipId = membershipId
        UserDefaultsManager.shared.widgetChapters = chapters
        UserDefaultsManager.shared.accessToken = accessToken
        UserDefaultsManager.shared.refreshToken = refreshToken
        WidgetManager.shared.reloadTimelines()
    }

    public func clear() {
        UserDefaultsManager.shared.clearSession()
    }
}
