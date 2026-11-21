//
//  AppSettings.swift
//  Exchange-Traded Habits
//
//  The user's settings. They are stored in UserDefaults, which is roughly
//  macOS's `localStorage`: a small key-value store that survives restarts.
//  Views read them with @AppStorage(key), which works like a useState hook
//  that is saved automatically and updates every view using the same key.
//

import Foundation

enum AppSettings {
    /// Whether the Apple Intelligence features (the Insights panel) are shown.
    static let aiEnabledKey = "aiFeaturesEnabled"
    static let aiEnabledDefault = true

    /// The currency label shown next to all values, e.g. "CHF" or "€".
    static let currencyKey = "currency"
    static let defaultCurrency = "CHF"
    /// Long enough for codes and symbols, short enough to keep values readable.
    static let maxCurrencyLength = 6

    /// Whether the daily reminders at 6:00, 12:00 and 18:00 are sent.
    static let notificationsEnabledKey = "notificationsEnabled"
    static let notificationsEnabledDefault = true

    /// The currency to show for what the user typed: trimmed, and the
    /// default if the field is empty.
    static func currency(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultCurrency : String(trimmed.prefix(maxCurrencyLength))
    }

    static var notificationsEnabled: Bool {
        UserDefaults.standard.object(forKey: notificationsEnabledKey) as? Bool ?? notificationsEnabledDefault
    }
}

enum AppConfig {
    /// The current currency setting, for places that read it once (the
    /// Add/Edit sheets and the Insights cards). The main window uses
    /// @AppStorage instead, so it updates live while the user types.
    static var currency: String {
        AppSettings.currency(from: UserDefaults.standard.string(forKey: AppSettings.currencyKey) ?? "")
    }
}
