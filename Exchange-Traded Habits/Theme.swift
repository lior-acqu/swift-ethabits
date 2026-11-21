//
//  Theme.swift
//  Exchange-Traded Habits
//
//  Colors and fonts, carried over from the web app's styles.css.
//  Think of this file as the app's "CSS variables".
//

import SwiftUI

enum Theme {
    static let background = Color(hex: 0x191919)
    static let surface = Color(hex: 0x2B2B2B)
    static let surfaceHover = Color(hex: 0x333333)
    static let border = Color(hex: 0x4B4B4B)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xC2C2C2)

    static let positive = Color(hex: 0x78C2FF)
    static let negative = Color(hex: 0xFF788E)
    static let neutral = Color(hex: 0xDFDFDF)
    /// Neutral pill buttons (Edit Habit, Done Yesterday). Darker than
    /// `neutral`, so their fill stays a dark grey like the other pills.
    static let muted = Color(hex: 0x9A9A9A)
    /// Destructive actions (Delete Habit): a deeper crimson than `negative`,
    /// so deleting doesn't look like marking a habit as missed.
    static let danger = Color(hex: 0xE0344F)

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

extension Color {
    /// The same color with its HSB saturation and brightness shifted by the
    /// given amounts (0.05 = 5 percentage points), like dragging the sliders
    /// in the macOS color picker. Greys have no hue, so for them only the
    /// brightness changes.
    func adjusted(saturation saturationChange: Double = 0, brightness brightnessChange: Double = 0) -> Color {
        guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return self }
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        rgb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let isGrey = saturation == 0
        return Color(
            hue: hue,
            saturation: isGrey ? 0 : min(max(saturation + saturationChange, 0), 1),
            brightness: min(max(brightness + brightnessChange, 0), 1),
            opacity: alpha
        )
    }
}

extension Font {
    /// The app's monospaced font (SF Mono, the system counterpart to Roboto Mono).
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    /// The regular (proportional) system font, for titles, habit names and
    /// descriptions. Everything else in the app is monospaced, because
    /// ContentView sets `.fontDesign(.monospaced)` for the whole window.
    /// That setting even overrides a font's own design, so this also resets
    /// the design for this view (like overriding an inherited CSS property).
    func sansFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.system(size: size, weight: weight)).fontDesign(.default)
    }
}
