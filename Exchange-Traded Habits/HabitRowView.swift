//
//  HabitCardView.swift
//  Exchange-Traded Habits
//
//  One habit entry in the grid: title, value, change, buttons and description.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(habit.name) (\(habit.shortName))")
                .font(.mono(22, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 10) {
                Text("\(currency) \(habit.currentValue, specifier: "%.2f")")
                    .font(.mono(16))
                    .foregroundStyle(Theme.textSecondary)
                ChangeBadge(changePercent: habit.changePercent)
            }
            .padding(.top, 10)
            .padding(.bottom, 18)

            // The buttons do nothing yet; their actions come in a later step.
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Button("Done") {}
                        .buttonStyle(HabitActionButtonStyle(isSelected: habit.completedToday))
                    Button("Missed") {}
                        .buttonStyle(HabitActionButtonStyle(isSelected: !habit.completedToday))
                    Button("Done Yesterday") {}
                        .buttonStyle(HabitActionButtonStyle())
                }
                HStack(spacing: 6) {
                    Button("Edit Habit") {}
                        .buttonStyle(HabitActionButtonStyle())
                    Button("Delete Habit") {}
                        .buttonStyle(HabitActionButtonStyle(isDestructive: true))
                }
            }

            Text(habit.details)
                .font(.mono(14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 15)
    }
}

/// The colored pill showing the change in percent.
struct ChangeBadge: View {
    let changePercent: Double

    var body: some View {
        Text("\(changePercent, specifier: "%.2f")%")
            .font(.mono(13))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .background(Theme.trendColor(forChange: changePercent).opacity(0.33), in: Capsule())
    }
}

/// The Notion-like button look of the web app (`.habit-action-button`).
struct HabitActionButtonStyle: ButtonStyle {
    var isSelected = false
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        HabitActionButton(configuration: configuration, isSelected: isSelected, isDestructive: isDestructive)
    }

    // A separate view, because hover state needs somewhere to live.
    private struct HabitActionButton: View {
        let configuration: Configuration
        let isSelected: Bool
        let isDestructive: Bool
        @State private var isHovered = false

        private var fill: Color {
            if isDestructive {
                return Color(hex: 0xFF5D78).opacity(isHovered ? 0.47 : 0.33)
            }
            return isHovered ? Theme.surfaceHover : Theme.surface
        }

        private var stroke: Color {
            if isSelected { return .white }
            return isDestructive ? Color(hex: 0xFFA5B4).opacity(0.47) : Theme.border
        }

        var body: some View {
            configuration.label
                .font(.mono(13))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(fill, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(stroke, lineWidth: 1))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .onHover { isHovered = $0 }
        }
    }
}

#Preview {
    HabitCardView(habit: DummyData.habits[0], currency: DummyData.currency)
        .frame(width: 360)
        .padding(40)
        .background(Theme.background)
}
