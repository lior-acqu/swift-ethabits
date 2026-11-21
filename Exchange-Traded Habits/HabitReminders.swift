//
//  HabitReminders.swift
//  Exchange-Traded Habits
//
//  Daily reminders to log the habits, at 6:00, 12:00 and 18:00.
//
//  They are local notifications: the app hands them to macOS once, and
//  macOS delivers them every day at those times, even when the app is
//  closed. Similar to scheduling with expo-notifications in React Native,
//  but nothing is sent through a server.
//

import Foundation
import UserNotifications

enum HabitReminders {
    /// One daily reminder.
    struct Reminder {
        let hour: Int
        let title: String
        let body: String

        /// A fixed identifier per time slot, so scheduling again replaces
        /// the existing reminder instead of adding a duplicate.
        var identifier: String { "habit-reminder-\(hour)" }
    }

    static let reminders = [
        Reminder(
            hour: 6,
            title: "Good Morning",
            body: "A new trading day for your habits. Log what you've done so far."
        ),
        Reminder(
            hour: 12,
            title: "Midday Check-In",
            body: "How are your habits doing today? Take a moment to log them."
        ),
        Reminder(
            hour: 18,
            title: "Evening Check-In",
            body: "Log today's habits before the day closes, so your portfolio stays up to date."
        ),
    ]

    /// Shows reminders as banners even while the app is in front.
    private static let delegate = ReminderDelegate()

    /// Applies the Notifications setting: schedules the three daily
    /// reminders when it is on, removes them when it is off. Safe to call
    /// on every launch and whenever the setting changes.
    static func refresh() async {
        let center = UNUserNotificationCenter.current()
        center.delegate = delegate

        guard AppSettings.notificationsEnabled else {
            let identifiers = reminders.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
            return
        }

        // Asks for permission; macOS only shows the prompt the first time.
        let isAllowed: Bool
        do {
            isAllowed = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return
        }
        // If notifications are turned off in System Settings, there is
        // nothing to schedule. The Settings panel explains how to fix that.
        guard isAllowed else { return }

        for reminder in reminders {
            try? await center.add(request(for: reminder))
        }
    }

    /// Whether macOS allows this app to show notifications, for the
    /// Settings panel. `.denied` means they are off in System Settings.
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// The notification for a reminder, repeating every day at its hour.
    static func request(for reminder: Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default

        // Only hour and minute are set, so it matches every day.
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: reminder.hour, minute: 0),
            repeats: true
        )
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }
}

/// By default, macOS hides notifications from the app that is in front.
/// This delegate shows them anyway, since a reminder is still useful then.
private final class ReminderDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
