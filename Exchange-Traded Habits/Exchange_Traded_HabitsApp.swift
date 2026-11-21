//
//  Exchange_Traded_HabitsApp.swift
//  Exchange-Traded Habits
//
//  Created by Lior on 14.11.2026.
//

import SwiftData
import SwiftUI

@main
struct Exchange_Traded_HabitsApp: App {
    /// The local database. SwiftData keeps it in the app's sandbox container.
    private let modelContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: Habit.self, HabitLog.self)
            DummyData.seedIfNeeded(into: container.mainContext)
            HabitTracker.fillMissingDays(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not open the habit store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Schedule the daily reminders at 6:00, 12:00 and 18:00 (or
                // remove them, if turned off in Settings), like a useEffect on mount.
                .task { await HabitReminders.refresh() }
        }
        .defaultSize(width: 1100, height: 850)
        .modelContainer(modelContainer)
    }
}
