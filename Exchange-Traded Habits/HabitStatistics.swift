//
//  HabitStatistics.swift
//  Exchange-Traded Habits
//
//  The numbers behind the statistics grid, computed from all habits.
//

import Foundation

struct HabitStatistics {
    /// How the whole portfolio moved on one day compared to the day before.
    struct DailyChange {
        let date: Date
        /// Gain in currency (negative for a loss).
        let gain: Double
        /// Gain in percent of the previous day's value.
        let percent: Double

        var isNegative: Bool { gain < -0.000_001 }
    }

    struct HabitRate {
        let name: String
        let percent: Double
    }

    /// How many tracked habit entries a day had, and how many were done.
    struct DayCompletion {
        var done = 0
        var total = 0

        var ratio: Double { total == 0 ? 0 : Double(done) / Double(total) }
        var isPerfect: Bool { total > 0 && done == total }
    }

    /// A weekday or month with its completion rate.
    struct PeriodRate {
        let label: String
        let percent: Double
    }

    let dailyChanges: [DailyChange]
    let bestPercentDay: DailyChange?
    let bestGainDay: DailyChange?
    let worstPercentDay: DailyChange?
    let longestStreak: Int
    let currentStreak: Int
    /// Share of finished days (before today) on which a habit was done, in percent.
    let completionRate: Double?
    let totalCompleted: Int
    let daysTracking: Int
    let firstTrackedDay: Date?
    let mostConsistent: HabitRate?
    let allTimeHigh: PortfolioPoint?
    /// The average daily change of the portfolio, compounded, in percent.
    let averageDailyGrowth: Double?
    /// Done / total entries per day (starting entries left out). Feeds the heatmap.
    let completionByDay: [Date: DayCompletion]
    /// Days on which every tracked habit was done.
    let perfectDays: Int
    let bestWeekday: PeriodRate?
    let bestMonth: PeriodRate?

    init(habits: [Habit], now: Date = .now) {
        let today = Calendar.current.startOfDay(for: now)

        // MARK: Daily portfolio changes
        // Each habit's value per day. A day's gain only counts habits that
        // have an entry on both days, so adding a habit is not a "gain".
        let valuesByHabit: [[Date: Double]] = habits.map { habit in
            Dictionary(habit.logs.map { ($0.date, $0.value) }, uniquingKeysWith: { first, _ in first })
        }
        let allDays = Set(valuesByHabit.flatMap(\.keys)).sorted()

        var changes: [DailyChange] = []
        for (previous, day) in zip(allDays, allDays.dropFirst()) {
            var gain = 0.0
            var base = 0.0
            for values in valuesByHabit {
                guard let before = values[previous], let after = values[day] else { continue }
                gain += after - before
                base += before
            }
            guard base > 0 else { continue }
            changes.append(DailyChange(date: day, gain: gain, percent: gain / base * 100))
        }
        dailyChanges = changes
        bestPercentDay = changes.max { $0.percent < $1.percent }
        bestGainDay = changes.max { $0.gain < $1.gain }
        worstPercentDay = changes.min { $0.percent < $1.percent }

        // MARK: Streaks of days without a loss
        // Today is still in progress, so a loss today doesn't break the streak yet.
        let finished = changes.filter { $0.date < today || !$0.isNegative }
        var longest = 0
        var run = 0
        for change in finished {
            run = change.isNegative ? 0 : run + 1
            longest = max(longest, run)
        }
        longestStreak = longest
        currentStreak = run

        // MARK: Completion
        // Starting entries (filled in when a habit is added) are not real tracking.
        let tracked = habits.flatMap(\.logs).filter { !$0.isStartingEntry }
        let finishedEntries = tracked.filter { $0.date < today }
        completionRate = finishedEntries.isEmpty
            ? nil
            : Double(finishedEntries.filter(\.completed).count) / Double(finishedEntries.count) * 100
        totalCompleted = tracked.filter(\.completed).count

        let trackedDays = Set(tracked.map(\.date))
        daysTracking = trackedDays.count
        firstTrackedDay = trackedDays.min()

        // MARK: Most consistent habit
        mostConsistent = habits.compactMap { habit -> HabitRate? in
            let entries = habit.logs.filter { !$0.isStartingEntry && $0.date < today }
            guard !entries.isEmpty else { return nil }
            let done = entries.filter(\.completed).count
            return HabitRate(name: habit.name, percent: Double(done) / Double(entries.count) * 100)
        }
        .max { $0.percent < $1.percent }

        allTimeHigh = habits.portfolioHistory().max { $0.value < $1.value }

        // MARK: Average daily growth
        // The geometric mean: the steady daily rate that would have led to
        // the same result, like an average annual return in finance.
        if changes.isEmpty {
            averageDailyGrowth = nil
        } else {
            let growth = changes.reduce(1.0) { $0 * (1 + $1.percent / 100) }
            averageDailyGrowth = (pow(growth, 1 / Double(changes.count)) - 1) * 100
        }

        // MARK: Completion per day, perfect days
        var byDay: [Date: DayCompletion] = [:]
        for entry in tracked {
            byDay[entry.date, default: DayCompletion()].total += 1
            if entry.completed { byDay[entry.date, default: DayCompletion()].done += 1 }
        }
        completionByDay = byDay
        perfectDays = byDay.values.filter(\.isPerfect).count

        // MARK: Best weekday and month (by completion rate, finished days)
        let calendar = Calendar.current
        func bestPeriod(label: (Date) -> String) -> PeriodRate? {
            var groups: [String: DayCompletion] = [:]
            for entry in finishedEntries {
                groups[label(entry.date), default: DayCompletion()].total += 1
                if entry.completed { groups[label(entry.date), default: DayCompletion()].done += 1 }
            }
            return groups
                .map { PeriodRate(label: $0.key, percent: $0.value.ratio * 100) }
                // Ties go to the alphabetically first label, so the result is stable.
                .max { ($0.percent, $1.label) < ($1.percent, $0.label) }
        }
        bestWeekday = bestPeriod { calendar.weekdaySymbols[calendar.component(.weekday, from: $0) - 1] }
        bestMonth = bestPeriod { $0.formatted(.dateTime.month(.wide).year()) }
    }
}
