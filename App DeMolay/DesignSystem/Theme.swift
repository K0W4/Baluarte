import SwiftUI

public struct Theme {
    public static let backgroundPrimary = Color(UIColor.systemBackground)
    public static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    public static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)

    public static let textPrimary = Color(UIColor.label)
    public static let textSecondary = Color(UIColor.secondaryLabel)
    public static let textTertiary = Color(UIColor.tertiaryLabel)

    public static let accent = Color.accentColor
    public static let accentSecondary = Color.accentColor.opacity(0.6)
    public static let accentTertiary = Color.accentColor.opacity(0.3)
    
    public static let destructive = Color(UIColor.systemRed)
    public static let success = Color(UIColor.systemGreen)
    public static let warning = Color(UIColor.systemOrange)

    public static let border = Color(UIColor.separator)
    public static let cardBackground = Color(UIColor.secondarySystemBackground)
}
