import SwiftUI

enum DesignTokens {
    enum ColorToken {
        static let income = Color(red: 0.16, green: 0.62, blue: 0.56)
        static let expense = Color(red: 0.91, green: 0.34, blue: 0.24)
        static let mutedText = Color.secondary
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 8
        static let control: CGFloat = 8
    }
}
