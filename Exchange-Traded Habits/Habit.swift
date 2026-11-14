//
//  Habit.swift
//  Exchange-Traded Habits
//
//  The data types. They mirror the old `habits` and `habit_logs` tables.
//  For now they are plain structs; once we store data locally they become
//  SwiftData models.
//

import Foundation

/// One day of one habit (a row of the old `habit_logs` table).
struct HabitLog: Identifiable {
    let date: Date
    let value: Double
    let completed: Bool

    var id: Date { date }
}

struct Habit: Identifiable {
    let id = UUID()
    var name: String
    var shortName: String
    var details: String
    /// How often the habit is performed, in days (daily = 1).
    var interval: Double
    var initialValue: Double
    /// Oldest first; the last entry is today.
    var logs: [HabitLog]

    var currentValue: Double { logs.last?.value ?? initialValue }

    /// Change since the habit was created, in percent.
    var changePercent: Double { currentValue / initialValue * 100 - 100 }

    var completedToday: Bool { logs.last?.completed ?? false }

    /// Ticker-style name: the first four non-vowel characters, padded with "X".
    /// Same logic as `create_short_name` in the old app.py.
    static func makeShortName(from name: String) -> String {
        let skipped: Set<Character> = ["a", "e", "i", "o", "u", " ", ",", "."]
        let letters = name.filter { !skipped.contains($0) }.prefix(4).uppercased()
        return letters.padding(toLength: 4, withPad: "X", startingAt: 0)
    }

    /// importance · difficulty · (ln(interval) + 1), as in the old app.py.
    static func makeInitialValue(importance: Int, difficulty: Int, interval: Double) -> Double {
        Double(importance * difficulty) * (log(interval) + 1)
    }
}

/// One point of the total-portfolio graph: the sum of all habit values on a day.
struct PortfolioPoint: Identifiable {
    let date: Date
    let value: Double

    var id: Date { date }
}
