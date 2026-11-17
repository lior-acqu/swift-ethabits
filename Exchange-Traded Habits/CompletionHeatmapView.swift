//
//  CompletionHeatmapView.swift
//  Exchange-Traded Habits
//
//  A GitHub-style heatmap: one square per day, one column per week.
//  Dark when nothing was done, brighter the more habits were done,
//  glowing blue when every habit was done.
//

import SwiftData
import SwiftUI

struct CompletionHeatmapView: View {
    let completionByDay: [Date: HabitStatistics.DayCompletion]

    private let cellSize: CGFloat = 13
    private let spacing: CGFloat = 3
    private let labelWidth: CGFloat = 32
    private let maxWeeks = 53

    /// The available width, measured to decide how many weeks fit.
    @State private var width: CGFloat = 0

    private var calendar: Calendar { .current }
    private var today: Date { calendar.startOfDay(for: .now) }

    private var weekCount: Int {
        let fitting = Int((width - labelWidth + spacing) / (cellSize + spacing))
        return min(max(fitting, 1), maxWeeks)
    }

    /// The first day of each visible week, oldest first. The last one is this week.
    private var weekStarts: [Date] {
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<weekCount).reversed().map {
            calendar.date(byAdding: .weekOfYear, value: -$0, to: thisWeek)!
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.mono(26, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                monthLabels
                HStack(alignment: .top, spacing: spacing) {
                    weekdayLabels
                    ForEach(weekStarts, id: \.self) { weekStart in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { offset in
                                cell(for: calendar.date(byAdding: .day, value: offset, to: weekStart)!)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }

            legend
        }
    }

    // MARK: - Cells

    @ViewBuilder
    private func cell(for day: Date) -> some View {
        if day > today {
            // The rest of this week: leave the space empty.
            Color.clear.frame(width: cellSize, height: cellSize)
        } else {
            let completion = completionByDay[day]
            RoundedRectangle(cornerRadius: 3)
                .fill(color(for: completion))
                .frame(width: cellSize, height: cellSize)
                .shadow(color: completion?.isPerfect == true ? Theme.positive.opacity(0.9) : .clear, radius: 4)
                .overlay {
                    // Mark today with a thin outline.
                    if day == today {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                    }
                }
                .help(tooltip(for: day, completion: completion))
        }
    }

    private func color(for completion: HabitStatistics.DayCompletion?) -> Color {
        guard let completion, completion.total > 0 else {
            // No habits tracked that day.
            return Theme.surface.opacity(0.5)
        }
        if completion.isPerfect { return Theme.positive }
        if completion.done == 0 { return Theme.surface }
        // Partly done: from a dim to a fairly bright blue.
        return Theme.positive.opacity(0.18 + 0.5 * completion.ratio)
    }

    private func tooltip(for day: Date, completion: HabitStatistics.DayCompletion?) -> String {
        let date = day.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
        guard let completion, completion.total > 0 else { return "\(date): no habits tracked" }
        if completion.isPerfect { return "\(date): all \(completion.total) habits done" }
        return "\(date): \(completion.done) of \(completion.total) habits done"
    }

    // MARK: - Labels

    /// Month names above the first week of each month, skipped when they would overlap.
    private var monthLabels: some View {
        let columnWidth = cellSize + spacing
        var lastLabelColumn = -10
        let labels: [(column: Int, text: String)] = weekStarts.enumerated().compactMap { column, weekStart in
            let lastDay = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let startsMonth = calendar.component(.month, from: weekStart) != calendar.component(.month, from: lastDay)
                || calendar.component(.day, from: weekStart) == 1
            guard column == 0 || startsMonth, column - lastLabelColumn >= 3 else { return nil }
            lastLabelColumn = column
            return (column, lastDay.formatted(.dateTime.month(.abbreviated)))
        }

        return ZStack(alignment: .topLeading) {
            ForEach(labels, id: \.column) { label in
                Text(label.text)
                    .font(.mono(11))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize()
                    .offset(x: labelWidth + spacing + CGFloat(label.column) * columnWidth)
            }
        }
        .frame(height: 14, alignment: .topLeading)
    }

    /// Every other weekday name down the left side, like on GitHub.
    private var weekdayLabels: some View {
        let symbols = calendar.shortWeekdaySymbols
        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<7, id: \.self) { row in
                let index = (calendar.firstWeekday - 1 + row) % 7
                Text(row % 2 == 1 ? symbols[index] : "")
                    .font(.mono(10))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: labelWidth, height: cellSize, alignment: .leading)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: spacing) {
            Text("Less")
                .padding(.trailing, 4)
            ForEach([0.0, 0.25, 0.5, 0.75], id: \.self) { ratio in
                RoundedRectangle(cornerRadius: 3)
                    .fill(ratio == 0 ? Theme.surface : Theme.positive.opacity(0.18 + 0.5 * ratio))
                    .frame(width: cellSize, height: cellSize)
            }
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.positive)
                .frame(width: cellSize, height: cellSize)
                .shadow(color: Theme.positive.opacity(0.9), radius: 4)
            Text("All done")
                .padding(.leading, 4)
        }
        .font(.mono(11))
        .foregroundStyle(Theme.textSecondary)
    }
}

#Preview {
    let container = DummyData.previewContainer
    CompletionHeatmapView(
        completionByDay: HabitStatistics(habits: DummyData.previewHabits(in: container)).completionByDay
    )
    .padding(40)
    .frame(width: 900)
    .background(Theme.background)
    .modelContainer(container)
}
