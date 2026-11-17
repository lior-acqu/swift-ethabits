//
//  DummyData.swift
//  Exchange-Traded Habits
//
//  Placeholder habits. They are put into the local store once, on the very
//  first launch, and are also used by the Xcode previews.
//

import Foundation
import SwiftData

enum DummyData {
    private static let seededKey = "didSeedDummyData"

    /// Inserts the dummy habits on the first launch only. Once they are
    /// deleted they stay deleted, because the flag is remembered.
    static func seedIfNeeded(into context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }
        if (try? context.fetchCount(FetchDescriptor<Habit>())) == 0 {
            insert(into: context)
            try? context.save()
        }
        defaults.set(true, forKey: seededKey)
    }

    /// A throwaway in-memory store with the dummy habits, for previews.
    static var previewContainer: ModelContainer {
        let container = try! ModelContainer(
            for: Habit.self, HabitLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        insert(into: container.mainContext)
        return container
    }

    /// The preview store's habits, in the order they were added.
    static func previewHabits(in container: ModelContainer) -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
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

    private static func insert(into context: ModelContext, days: Int = 30) {
        // A fixed seed, so the dummy data looks the same every time.
        var random = SeededGenerator(seed: 42)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for (index, spec) in specs.enumerated() {
            let initialValue = Habit.makeInitialValue(
                importance: spec.importance, difficulty: spec.difficulty, interval: spec.interval)
            let habit = Habit(
                name: spec.name,
                shortName: Habit.makeShortName(from: spec.name),
                details: Habit.makeDetails(interval: spec.interval, time: spec.time, identity: spec.identity),
                interval: spec.interval,
                initialValue: initialValue,
                // One second apart, so they keep this order.
                createdAt: .now.addingTimeInterval(Double(index - specs.count))
            )
            context.insert(habit)

            var value = initialValue
            for daysAgo in (0..<days).reversed() {
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                let completed = Double.random(in: 0..<1, using: &random) < spec.completionRate
                // +1% when done, -1% (spread over the interval) when missed.
                value *= completed ? 1.01 : 1 - 0.01 / spec.interval
                habit.logs.append(HabitLog(date: date, value: value, completed: completed))
            }
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
