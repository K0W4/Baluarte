import SwiftUI

public struct Typography {
    public static let largeTitle = Font.system(.largeTitle, design: .rounded)
    public static let title1 = Font.system(.title, design: .rounded)
    public static let title2 = Font.system(.title2, design: .rounded)
    public static let title3 = Font.system(.title3, design: .rounded)
    public static let headline = Font.system(.headline, design: .rounded)
    public static let body = Font.system(.body, design: .rounded)
    public static let callout = Font.system(.callout, design: .rounded)
    public static let subheadline = Font.system(.subheadline, design: .rounded)
    public static let footnote = Font.system(.footnote, design: .rounded)
    public static let caption1 = Font.system(.caption, design: .rounded)
    public static let caption2 = Font.system(.caption2, design: .rounded)
    public static let numericDisplay = Font.system(.title, design: .rounded).bold()
}
