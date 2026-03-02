import SwiftUI

/// Centralised design tokens — corner radii and spacing.
/// Colours live in `ColorExtension.swift` as `Color.app*` statics.
enum AppTheme {

    // MARK: - Corner Radii

    enum Radius {
        static let small:  CGFloat = 8
        static let medium: CGFloat = 12
        static let large:  CGFloat = 16
        static let card:   CGFloat = 20
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
}
