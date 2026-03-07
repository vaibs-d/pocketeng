import SwiftUI

// MARK: - Brand Colors (monochrome dev tool palette)
extension Color {
    /// Primary accent — terminal green for active/success states
    static let accent = Color(red: 0.2, green: 0.84, blue: 0.4)

    /// Surface colors for dark UI
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let surfaceRaised = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let surfaceBorder = Color.white.opacity(0.08)

    /// Text hierarchy
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.3)
    static let textMuted = Color.white.opacity(0.15)

    // Legacy aliases (kept for compatibility during transition)
    static let brandPurple = Color.accent
    static let brandIndigo = Color.surface
    static let brandCyan = Color.accent
    static let brandDark = Color.black
}

// MARK: - Cross-platform color helpers
extension Color {
    static var systemGray6Color: Color {
        Color.surfaceRaised
    }

    static var systemBackgroundColor: Color {
        Color.surface
    }

    static var secondarySystemBackgroundColor: Color {
        Color.surfaceRaised
    }

    static var systemGray5Color: Color {
        Color.surfaceBorder
    }

    static var tertiaryColor: Color {
        Color.textTertiary
    }

    static var systemYellowLight: Color {
        Color.yellow.opacity(0.1)
    }

    static var redLight: Color {
        Color.red.opacity(0.1)
    }
}

// MARK: - Cross-platform view modifiers
extension View {
    @ViewBuilder
    func iOSNavigationBarTitleDisplayMode() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
