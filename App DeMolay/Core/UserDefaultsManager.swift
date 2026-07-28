import Foundation

public struct UserDefaultsManager {
    public static let shared = UserDefaultsManager()
    
    private let defaults: UserDefaults
    
    private init() {
        self.defaults = UserDefaults(suiteName: "group.com.kowa.baluarte") ?? .standard
    }
    
    public var currentChapterId: UUID? {
        get {
            guard let string = defaults.string(forKey: "currentChapterId") else { return nil }
            return UUID(uuidString: string)
        }
        nonmutating set {
            defaults.set(newValue?.uuidString, forKey: "currentChapterId")
        }
    }
    
    public var currentUserId: UUID? {
        get {
            guard let string = defaults.string(forKey: "currentUserId") else { return nil }
            return UUID(uuidString: string)
        }
        nonmutating set {
            defaults.set(newValue?.uuidString, forKey: "currentUserId")
        }
    }
}
