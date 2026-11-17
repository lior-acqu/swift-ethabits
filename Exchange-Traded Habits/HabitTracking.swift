//
//  HabitTracking.swift
//  Exchange-Traded Habits
//
//  The daily bookkeeping: adding an entry for every day, and marking days as
//  done or missed. A port of `createMissingHabitLogs`, `/complete`, `/miss`
//  and `/yesterday` in the old app.py.
//
//  The rule behind every value: each day's value is the previous day's value
//  times 1.01 if the habit was done, or times (1 - 0.01 / interval) if not.
//

import Foundation
import SwiftData

extension Habit {
    /// Growth on a day the habit was done: +1%.
    static let doneFactor = 1.01

    /// Shrinkage on a day the habit was not done: -1%, spread over the interval.
    var missedFactor: Double { 1 - 0.01 / interval }

    /// The entry for a given day, if there is one.
    func log(on date: Date) -> HabitLog? {
        let day = Calendar.current.startOfDay(for: date)
        return logs.first { $0.date == day }
    }

    /// Adds a "not done" entry for every day from the last entry up to today.
    /// Unlike the web app, this also covers days the app was not opened.
    func fillMissingDays(until date: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        guard let last = sortedLogs.last else {
            logs.append(HabitLog(date: today, value: initialValue * missedFactor, completed: false))
            return
        }

        var day = last.date
        var value = last.value
        while let next = calendar.date(byAdding: .day, value: 1, to: day), next <= today {
            value *= missedFactor
            logs.append(HabitLog(date: next, value: value, completed: false))
            day = next
        }
    }

    /// Marks a day as done or not done. That day's value and every later value
    /// are adjusted, because each value builds on the one before it.
    /// Returns false if there is no entry for that day or nothing changed.
    @discardableResult
    func setCompleted(_ completed: Bool, on date: Date) -> Bool {
        guard let entry = log(on: date), entry.completed != completed else { return false }
        let factor = completed ? Self.doneFactor / missedFactor : missedFactor / Self.doneFactor
        entry.completed = completed
        for later in logs where later.date >= entry.date {
            later.value *= factor
        }
        return true
    }

    /// Changes the starting value. All entries scale with it, so the change
    /// in percent stays the same (as in the old edit route).
    func setInitialValue(_ newValue: Double) {
        guard newValue > 0, initialValue > 0 else { return }
        let factor = newValue / initialValue
        for entry in logs {
            entry.value *= factor
        }
        initialValue = newValue
    }
}

enum HabitTracker {
    /// Brings every habit up to today. Called on launch, when the app becomes
    /// active and when the day changes at midnight.
    static func fillMissingDays(in context: ModelContext) {
        guard let habits = try? context.fetch(FetchDescriptor<Habit>()) else { return }
        for habit in habits {
            habit.fillMissingDays()
        }
        try? context.save()
    }
}
