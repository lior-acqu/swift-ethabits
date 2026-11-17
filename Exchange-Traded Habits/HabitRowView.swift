//
//  HabitRowView.swift
//  Exchange-Traded Habits
//
//  One habit in the sidebar: title, short name, value, change,
//  buttons and description.
//

import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            // The buttons do nothing yet; their actions come in a later step.
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Button("Done") {}
                        .habitButtonStyle(highlighted: habit.completedToday, tint: Theme.positive)
                    Button("Missed") {}
                        .habitButtonStyle(highlighted: !habit.completedToday, tint: Theme.negative)
                    Button("Done Yesterday") {}
                        .habitButtonStyle()
                }
                HStack(spacing: 6) {
                    Button("Edit Habit", systemImage: "pencil") {}
                        .habitButtonStyle()
                    Button("Delete Habit", systemImage: "trash", role: .destructive) {}
                        .habitButtonStyle()
                        .foregroundStyle(Theme.negative)
                }
            }
            .controlSize(.small)

            Text(habit.details)
                .font(.mono(12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    /// Name and short name on the left, value and change on the right,
    /// like a ticker row in Stocks.
    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.mono(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(habit.shortName)
                    .font(.mono(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .lineLimit(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currency) \(habit.currentValue, specifier: "%.2f")")
                    .font(.mono(15, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                ChangeBadge(changePercent: habit.changePercent)
            }
        }
    }
}

/// The colored box showing the change in percent, like in Stocks.
struct ChangeBadge: View {
    let changePercent: Double

    var body: some View {
        Text("\(changePercent >= 0 ? "+" : "")\(changePercent, specifier: "%.2f")%")
            .font(.mono(12, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .frame(minWidth: 64, alignment: .trailing)
            .background(Theme.trendColor(forChange: changePercent), in: RoundedRectangle(cornerRadius: 5))
    }
}

extension View {
    /// Liquid Glass buttons. A highlighted button (e.g. "Done" when the habit
    /// is completed today) is filled with the tint color.
    @ViewBuilder
    func habitButtonStyle(highlighted: Bool = false, tint: Color? = nil) -> some View {
        if highlighted {
            buttonStyle(.glassProminent)
                .tint(tint)
                .foregroundStyle(.black)
        } else {
            buttonStyle(.glass)
        }
    }
}

#Preview {
    List(DummyData.habits) { habit in
        HabitRowView(habit: habit, currency: DummyData.currency)
    }
    .listStyle(.sidebar)
    .frame(width: 340, height: 600)
}
