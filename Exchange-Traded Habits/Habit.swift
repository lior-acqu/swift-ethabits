//
//  Habit.swift
//  Exchange-Traded Habits
//
//  The data types. They mirror the old `habits` and `habit_logs` tables and
//  are stored locally with SwiftData (Apple's built-in database layer).
//  `@Model` makes a class storable, a bit like defining a table.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var name: String
    var shortName: String
    var details: String
    /// How often the habit is performed, in days (daily = 1).
    var interval: Double
    var initialValue: Double
    /// Used to keep the habits in the order they were added.
    var createdAt: Date

    /// One entry per day. Deleting a habit deletes its logs too.
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    init(name: String, shortName: String, details: String, interval: Double,
         initialValue: Double, createdAt: Date = .now) {
        self.name = name
        self.shortName = shortName
        self.details = details
        self.interval = interval
        self.initialValue = initialValue
        self.createdAt = createdAt
    }

    /// The logs oldest first (SwiftData does not keep them in order).
    var sortedLogs: [HabitLog] { logs.sorted { $0.date < $1.date } }

    var currentValue: Double { sortedLogs.last?.value ?? initialValue }

    /// Change since the habit was created, in percent.
    var changePercent: Double { currentValue / initialValue * 100 - 100 }

    var completedToday: Bool { log(on: .now)?.completed ?? false }

    /// "Done Yesterday" only makes sense if yesterday has an entry that is not done yet.
    var canCompleteYesterday: Bool {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now),
              let entry = log(on: yesterday) else { return false }
        return !entry.completed
    }
}

/// One day of one habit (a row of the old `habit_logs` table).
@Model
final class HabitLog {
    /// Always the start of a day, so logs of different habits line up.
    var date: Date
    var value: Double
    var completed: Bool
    /// True for the entries filled in with the starting value when a habit is
    /// added (yesterday and earlier). They are not real tracking, so the
    /// statistics skip them. The default lets existing stores upgrade.
    var isStartingEntry: Bool = false
    var habit: Habit?

    init(date: Date, value: Double, completed: Bool, isStartingEntry: Bool = false) {
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.completed = completed
        self.isStartingEntry = isStartingEntry
    }
}

// MARK: - Creating habits

extension Habit {
    /// Creates a habit with its first logs and saves it.
    /// A port of `add_habit` in the old app.py.
    @discardableResult
    static func create(
        name: String, time: String, identity: String,
        importance: Int, difficulty: Int, interval: Double,
        in context: ModelContext
    ) throws -> Habit {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        func daysAgo(_ days: Int) -> Date { calendar.date(byAdding: .day, value: -days, to: today)! }

        // Days that already have entries, so the new habit's history lines up
        // with the existing ones. Read before inserting anything new.
        let existingDays = Set(try context.fetch(FetchDescriptor<HabitLog>()).map(\.date))

        let initialValue = makeInitialValue(importance: importance, difficulty: difficulty, interval: interval)
        let habit = Habit(
            name: name,
            shortName: makeShortName(from: name),
            details: makeDetails(interval: interval, time: time, identity: identity),
            interval: interval,
            initialValue: initialValue
        )
        context.insert(habit)

        // Today starts as "not done yet": -1% spread over the interval.
        habit.logs.append(HabitLog(date: today, value: initialValue * (1 - 0.01 / interval), completed: false))
        // Yesterday holds the starting value.
        habit.logs.append(HabitLog(date: daysAgo(1), value: initialValue, completed: true, isStartingEntry: true))
        // Before that, fill in the starting value for every earlier day
        // that the other habits already have an entry for.
        var daysBack = 2
        while existingDays.contains(daysAgo(daysBack)) {
            habit.logs.append(HabitLog(date: daysAgo(daysBack), value: initialValue, completed: true, isStartingEntry: true))
            daysBack += 1
        }

        try context.save()
        return habit
    }

    /// Ticker-style name: the first four non-vowel characters, padded with "X".
    /// Same logic as `create_short_name` in the old app.py.
    static func makeShortName(from name: String) -> String {
        let skipped: Set<Character> = ["a", "e", "i", "o", "u", " ", ",", "."]
        let letters = name.filter { !skipped.contains($0) }.prefix(4).uppercased()
        return letters.padding(toLength: 4, withPad: "X", startingAt: 0)
    }

    /// importance · difficulty · (ln(interval) + 1), as in the old app.py.
    static func makeInitialValue(importance: Int, difficulty: Int, interval: Double) -> Double {
        // Foundation.log is the natural logarithm (ln); the prefix keeps it
        // apart from the habit's own `log(on:)` method.
        Double(importance * difficulty) * (Foundation.log(interval) + 1)
    }

    static func makeDetails(interval: Double, time: String, identity: String) -> String {
        let days = interval.formatted(.number.precision(.fractionLength(0...2)))
        return "Every \(days) day/s, I'll complete this habit when \(time) to become \(identity)."
    }
}

// MARK: - Portfolio

/// One point of the total-portfolio graph: the sum of all habit values on a day.
struct PortfolioPoint: Identifiable {
    let date: Date
    let value: Double

    var id: Date { date }
}

extension Sequence where Element == Habit {
    /// Sums up all habit values per day (the old `SUM(hl.value) ... GROUP BY hl.date` query).
    func portfolioHistory() -> [PortfolioPoint] {
        var totals: [Date: Double] = [:]
        for habit in self {
            for log in habit.logs {
                totals[log.date, default: 0] += log.value
            }
        }
        return totals
            .map { PortfolioPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

enum AppConfig {
    /// Was a per-user setting in the web app; hardcoded for now.
    static let currency = "CHF"
}
