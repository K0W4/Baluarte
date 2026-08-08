import Foundation
import WidgetKit

final class WidgetManager {
    static let shared = WidgetManager()
    
    private init() {}
    
    func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
