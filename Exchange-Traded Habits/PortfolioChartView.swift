//
//  PortfolioChartView.swift
//  Exchange-Traded Habits
//
//  The top section of the main page: title, total value and the graph.
//  Uses Swift Charts, Apple's built-in counterpart to Chart.js.
//

import Charts
import SwiftData
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Habit Portfolio")
                .sansFont(64, weight: .medium)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 40)

            Text("\(currency) \(currentValue, specifier: "%.2f") (\(changePercent, specifier: "%.2f")%)")
                .font(.mono(32))
                .foregroundStyle(Theme.textSecondary)

            chart
                .frame(height: 320)
                .padding(.top, 20)
        }
    }

    /// The day under the mouse pointer, while hovering over the graph.
    @State private var hoveredDate: Date?

    /// The point closest to the hovered day.
    private var hoveredPoint: PortfolioPoint? {
        guard let hoveredDate else { return nil }
        return history.min {
            abs($0.date.timeIntervalSince(hoveredDate)) < abs($1.date.timeIntervalSince(hoveredDate))
        }
    }

    private var chart: some View {
        Chart {
            ForEach(history) { point in
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

            if let hoveredPoint {
                // A thin vertical line and a bigger dot on the hovered day,
                // with the card above the dot.
                RuleMark(x: .value("Date", hoveredPoint.date))
                    .foregroundStyle(Theme.textSecondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                PointMark(
                    x: .value("Date", hoveredPoint.date),
                    y: .value("Value", hoveredPoint.value)
                )
                .symbolSize(90)
                .foregroundStyle(color)
                .annotation(
                    position: .top,
                    spacing: 12,
                    overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                ) {
                    HoverCard(
                        date: hoveredPoint.date,
                        value: "\(currency) \(hoveredPoint.value.formatted(.number.precision(.fractionLength(2))))"
                    )
                }
            }
        }
        // Track the mouse over the plot area and turn its position into a date.
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            guard let plotFrame = proxy.plotFrame else { return }
                            let x = location.x - geometry[plotFrame].origin.x
                            hoveredDate = proxy.value(atX: x, as: Date.self)
                        case .ended:
                            hoveredDate = nil
                        }
                    }
            }
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
    let container = DummyData.previewContainer
    PortfolioChartView(
        history: DummyData.previewHabits(in: container).portfolioHistory(),
        currency: AppConfig.currency
    )
    .padding(40)
    .background(Theme.background)
    .modelContainer(container)
}
