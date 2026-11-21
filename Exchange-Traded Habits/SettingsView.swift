//
//  SettingsView.swift
//  Exchange-Traded Habits
//
//  The Settings panel on the right, in the same floating glass panel as
//  the Insights panel. Every change is saved and applied immediately.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    // @AppStorage is like useState, but saved in UserDefaults and shared by
    // every view using the same key (see AppSettings.swift).
    @AppStorage(AppSettings.aiEnabledKey) private var aiEnabled = AppSettings.aiEnabledDefault
    @AppStorage(AppSettings.currencyKey) private var currency = AppSettings.defaultCurrency
    @AppStorage(AppSettings.notificationsEnabledKey) private var notificationsEnabled = AppSettings.notificationsEnabledDefault

    /// Whether macOS allows notifications for this app, checked when the
    /// panel opens and whenever the Reminders switch changes.
    @State private var notificationStatus: UNAuthorizationStatus?

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Settings")
                    .sansFont(22, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)

                aiSection
                Divider()
                currencySection
                Divider()
                remindersSection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Runs on appear and again whenever the switch changes, like a
        // useEffect with [notificationsEnabled] as its dependency.
        .task(id: notificationsEnabled) {
            await HabitReminders.refresh()
            notificationStatus = await HabitReminders.authorizationStatus()
        }
    }

    // MARK: - Sections

    private var aiSection: some View {
        switchRow(
            "Apple Intelligence",
            "Analyses and habit suggestions in the Insights panel. When off, the Insights button is removed and nothing is sent to the model.",
            isOn: $aiEnabled
        )
    }

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Currency", "The label shown next to all values, e.g. CHF, EUR or $. Only the label changes, not the values.")
            HStack(spacing: 10) {
                TextField("Currency", text: $currency, prompt: Text(AppSettings.defaultCurrency))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .onChange(of: currency) { _, newValue in
                        // Keep it short so values stay readable.
                        if newValue.count > AppSettings.maxCurrencyLength {
                            currency = String(newValue.prefix(AppSettings.maxCurrencyLength))
                        }
                    }
                Text("e.g. \(AppSettings.currency(from: currency)) 42.00")
                    .font(.mono(12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            switchRow(
                "Reminders",
                "A notification at 6:00, 12:00 and 18:00 every day to log your habits.",
                isOn: $notificationsEnabled
            )
            if notificationsEnabled && notificationStatus == .denied {
                VStack(alignment: .leading, spacing: 10) {
                    prose("Notifications for this app are turned off in System Settings, so the reminders can't be shown.", color: Theme.negative)
                    Button("Open Notification Settings", systemImage: "gear", action: openNotificationSettings)
                        .habitButtonStyle()
                        .controlSize(.small)
                }
            }
        }
    }

    /// Opens System Settings → Notifications for this app.
    private func openNotificationSettings() {
        let id = Bundle.main.bundleIdentifier ?? ""
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(id)") {
            openURL(url)
        }
    }

    // MARK: - Building blocks (same look as the Insights panel)

    private func switchRow(_ title: String, _ subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            header(title, subtitle)
            Spacer(minLength: 0)
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Theme.positive)
        }
    }

    private func header(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .sansFont(17, weight: .semibold)
                .foregroundStyle(Theme.textPrimary)
            prose(subtitle)
        }
    }

    private func prose(_ text: String, color: Color = Theme.textSecondary) -> some View {
        Text(text)
            .sansFont(13)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    SettingsView()
        .frame(width: 360, height: 700)
        .background(Theme.background)
}
