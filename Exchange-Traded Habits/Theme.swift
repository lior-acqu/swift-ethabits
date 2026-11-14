//
//  Theme.swift
//  Exchange-Traded Habits
//
//  Colors and fonts, carried over from the web app's styles.css.
//  Think of this file as the app's "CSS variables".
//

import SwiftUI

enum Theme {
    static let background = Color(hex: 0x1F1F1F)
    static let surface = Color(hex: 0x2B2B2B)
    static let surfaceHover = Color(hex: 0x333333)
    static let border = Color(hex: 0x4B4B4B)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xC2C2C2)

    static let positive = Color(hex: 0x78C2FF)
    static let negative = Color(hex: 0xFF788E)
    static let neutral = Color(hex: 0xDFDFDF)

    /// Blue for gains, red for losses, grey for (almost) no change.
    static func trendColor(forChange change: Double) -> Color {
        if change > 0.01 { return positive }
        if change < -0.01 { return negative }
        return neutral
    }
}

extension Color {
    /// Lets us write `Color(hex: 0x1F1F1F)` like a CSS hex color.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension Font {
    /// The app's monospaced font (SF Mono, the system counterpart to Roboto Mono).
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
