//
//  DummyData.swift
//  Exchange-Traded Habits
//
//  Placeholder data so the main page has something to show.
//  This whole file goes away once real, locally stored data exists.
//

import Foundation

enum DummyData {
    static let currency = "CHF"
    static let habits: [Habit] = makeHabits(days: 30)

    /// Sums up all habit values per day (the old `SUM(hl.value) ... GROUP BY hl.date` query).
    static func portfolioHistory(for habits: [Habit]) -> [PortfolioPoint] {
        var totals: [Date: Double] = [:]
        for habit in habits {
            for log in habit.logs {
                totals[log.date, default: 0] += log.value
            }
        }
        return totals
            .map { PortfolioPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Generation

    private struct Spec {
        let name: String
        let time: String
        let identity: String
        let importance: Int
        let difficulty: Int
        let interval: Double
        /// Chance of the habit being completed on any given day.
        let completionRate: Double
    }

    private static let specs: [Spec] = [
        Spec(name: "Morning Run", time: "I wake up", identity: "an athlete",
             importance: 8, difficulty: 7, interval: 2, completionRate: 0.6),
        Spec(name: "Reading", time: "I go to bed", identity: "a well-read person",
             importance: 7, difficulty: 4, interval: 1, completionRate: 0.85),
        Spec(name: "Meditation", time: "I finish breakfast", identity: "a calm person",
             importance: 6, difficulty: 6, interval: 1, completionRate: 0.5),
        Spec(name: "Coding Practice", time: "I come home", identity: "a great engineer",
             importance: 9, difficulty: 5, interval: 1, completionRate: 0.75),
        Spec(name: "Journaling", time: "I close my laptop", identity: "a reflective person",
             importance: 5, difficulty: 3, interval: 1, completionRate: 0.3),
        Spec(name: "Weekly Review", time: "it is Sunday evening", identity: "an organized person",
             importance: 8, difficulty: 6, interval: 7, completionRate: 0.2),
    ]

    private static func makeHabits(days: Int) -> [Habit] {
        // A fixed seed, so the dummy data looks the same on every launch.
        var random = SeededGenerator(seed: 42)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return specs.map { spec in
            let initialValue = Habit.makeInitialValue(
                importance: spec.importance, difficulty: spec.difficulty, interval: spec.interval)

            var value = initialValue
            var logs: [HabitLog] = []
            for daysAgo in (0..<days).reversed() {
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                let completed = Double.random(in: 0..<1, using: &random) < spec.completionRate
                // +1% when done, -1% (spread over the interval) when missed.
                value *= completed ? 1.01 : 1 - 0.01 / spec.interval
                logs.append(HabitLog(date: date, value: value, completed: completed))
            }

            let interval = spec.interval.formatted(.number.precision(.fractionLength(0...2)))
            return Habit(
                name: spec.name,
                shortName: Habit.makeShortName(from: spec.name),
                details: "Every \(interval) day/s, I'll complete this habit when \(spec.time) to become \(spec.identity).",
                interval: spec.interval,
                initialValue: initialValue,
                logs: logs
            )
        }
    }
}

/// A tiny deterministic random number generator (SplitMix64).
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
