//
//  StatisticsView.swift
//  Exchange-Traded Habits
//
//  The statistics below the graph: two columns, or one when space is tight.
//

import SwiftData
import SwiftUI

struct StatisticsView: View {
    let statistics: HabitStatistics
    let currency: String

    /// The available width, measured so the grid can switch to one column.
    @State private var width: CGFloat = 0

    private var columnCount: Int { width < 560 ? 1 : 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .sansFont(40, weight: .medium)
                .foregroundStyle(Theme.textPrimary)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 50, alignment: .top),
                    count: columnCount
                ),
                alignment: .leading,
                spacing: 0
            ) {
                ForEach(tiles(for: statistics)) { tile in
                    StatisticTileView(tile: tile)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    // MARK: - Tiles

    private func tiles(for s: HabitStatistics) -> [StatisticTile] {
        let notEnough = "Not enough history yet"
        return [
            StatisticTile(
                title: "Best Day (%)",
                value: s.bestPercentDay.map { signedPercent($0.percent) } ?? "–",
                detail: s.bestPercentDay.map { "on \(dayText($0.date))" } ?? notEnough,
                color: s.bestPercentDay.map { Theme.trendColor(forChange: $0.percent) }
            ),
            StatisticTile(
                title: "Best Day (Gain)",
                value: s.bestGainDay.map { signedMoney($0.gain) } ?? "–",
                detail: s.bestGainDay.map { "on \(dayText($0.date))" } ?? notEnough,
                color: s.bestGainDay.map { Theme.trendColor(forChange: $0.gain) }
            ),
            StatisticTile(
                title: "Worst Day (%)",
                value: s.worstPercentDay.map { signedPercent($0.percent) } ?? "–",
                detail: s.worstPercentDay.map { "on \(dayText($0.date))" } ?? notEnough,
                color: s.worstPercentDay.map { Theme.trendColor(forChange: $0.percent) }
            ),
            StatisticTile(
                title: "Average Daily Growth",
                value: s.averageDailyGrowth.map { signedPercent($0, digits: 3) } ?? "–",
                detail: "per day, compounded",
                color: s.averageDailyGrowth.map { Theme.trendColor(forChange: $0) }
            ),
            StatisticTile(
                title: "Longest Streak",
                value: daysText(s.longestStreak),
                detail: "in a row without a losing day"
            ),
            StatisticTile(
                title: "Current Streak",
                value: daysText(s.currentStreak),
                detail: s.currentStreak > 0 ? "and counting – keep it going" : "starts with your next good day"
            ),
            StatisticTile(
                title: "Average Completion",
                value: s.completionRate.map { "\($0.formatted(.number.precision(.fractionLength(1))))%" } ?? "–",
                detail: "of habit entries done (finished days)"
            ),
            StatisticTile(
                title: "Total Completed",
                value: s.totalCompleted.formatted(),
                detail: s.totalCompleted == 1 ? "habit completion" : "habit completions"
            ),
            StatisticTile(
                title: "Perfect Days",
                value: s.perfectDays.formatted(),
                detail: "every habit done"
            ),
            StatisticTile(
                title: "Days Tracking",
                value: s.daysTracking.formatted(),
                detail: s.firstTrackedDay.map { "since \(dayText($0))" } ?? "starting today"
            ),
            StatisticTile(
                title: "Best Weekday",
                value: s.bestWeekday?.label ?? "–",
                detail: s.bestWeekday.map { "\(wholePercent($0.percent)) of habits done" } ?? notEnough
            ),
            StatisticTile(
                title: "Best Month",
                value: s.bestMonth?.label ?? "–",
                detail: s.bestMonth.map { "\(wholePercent($0.percent)) of habits done" } ?? notEnough
            ),
            StatisticTile(
                title: "Most Consistent",
                value: s.mostConsistent?.name ?? "–",
                detail: s.mostConsistent.map { "done on \(wholePercent($0.percent)) of days" } ?? notEnough
            ),
            StatisticTile(
                title: "All-Time High",
                value: s.allTimeHigh.map { "\(currency) \($0.value.formatted(.number.precision(.fractionLength(2))))" } ?? "–",
                detail: s.allTimeHigh.map { "on \(dayText($0.date))" } ?? notEnough
            ),
        ]
    }

    // MARK: - Formatting

    private func signedPercent(_ value: Double, digits: Int = 2) -> String {
        (value >= 0 ? "+" : "") + value.formatted(.number.precision(.fractionLength(digits))) + "%"
    }

    private func wholePercent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0))) + "%"
    }

    private func signedMoney(_ value: Double) -> String {
        (value >= 0 ? "+" : "−") + "\(currency) " + abs(value).formatted(.number.precision(.fractionLength(2)))
    }

    private func dayText(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    private func daysText(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }
}

struct StatisticTile: Identifiable {
    let title: String
    let value: String
    let detail: String
    var color: Color? = nil

    var id: String { title }
}

/// One statistic, styled like the habit entries of the web app.
struct StatisticTileView: View {
    let tile: StatisticTile

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tile.title)
                .sansFont(16)
                .foregroundStyle(Theme.textSecondary)
            Text(tile.value)
                .font(.mono(40, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(tile.color ?? Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(tile.detail)
                .sansFont(13)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.border.opacity(0.6))
                .frame(height: 1)
        }
    }
}

#Preview {
    let container = DummyData.previewContainer
    ScrollView {
        StatisticsView(statistics: HabitStatistics(habits: DummyData.previewHabits(in: container)), currency: AppConfig.currency)
            .padding(40)
    }
    .frame(width: 760, height: 700)
    .background(Theme.background)
    .modelContainer(container)
}
