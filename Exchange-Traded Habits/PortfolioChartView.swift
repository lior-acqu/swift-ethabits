//
//  PortfolioChartView.swift
//  Exchange-Traded Habits
//
//  The top section of the main page: title, total value and the graph.
//  Uses Swift Charts, Apple's built-in counterpart to Chart.js.
//

import Charts
import SwiftUI

struct PortfolioChartView: View {
    let history: [PortfolioPoint]
    let currency: String

    private var currentValue: Double { history.last?.value ?? 0 }

    /// Change between the first and the last day shown, in percent.
    private var changePercent: Double {
        guard let first = history.first?.value, first != 0 else { return 0 }
        return currentValue / first * 100 - 100
    }

    private var color: Color { Theme.trendColor(forChange: changePercent) }

    /// The visible value range, with some breathing room above and below the line.
    private var yDomain: ClosedRange<Double> {
        let values = history.map(\.value)
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        let padding = max((high - low) * 0.15, 1)
        return (low - padding)...(high + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Habit Portfolio")
                .font(.mono(26, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            Text("\(currency) \(currentValue, specifier: "%.2f") (\(changePercent, specifier: "%.2f")%)")
                .font(.mono(16))
                .foregroundStyle(Theme.textSecondary)

            chart
                .frame(height: 320)
                .padding(.top, 20)
        }
    }

    private var chart: some View {
        Chart(history) { point in
            // The translucent fill below the line.
            AreaMark(
                x: .value("Date", point.date),
                yStart: .value("Base", yDomain.lowerBound),
                yEnd: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(color.opacity(0.13))

            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .foregroundStyle(color)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .symbolSize(22)
            .foregroundStyle(color)
        }
        .chartYScale(domain: yDomain)
        // Room on the right, so the last date label is not cut off.
        .chartXScale(range: .plotDimension(endPadding: 24))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 4)) {
                AxisGridLine().foregroundStyle(.white.opacity(0.05))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.mono(11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(.white.opacity(0.05))
                AxisValueLabel()
                    .font(.mono(11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

#Preview {
    PortfolioChartView(
        history: DummyData.portfolioHistory(for: DummyData.habits),
        currency: DummyData.currency
    )
    .padding(40)
    .background(Theme.background)
}
