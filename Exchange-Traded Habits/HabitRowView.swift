//
//  HabitRowView.swift
//  Exchange-Traded Habits
//
//  One habit in the sidebar: title, short name, value, change,
//  buttons and description.
//

import SwiftData
import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let currency: String

    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Button("Done") { setCompleted(true, daysAgo: 0) }
                        .buttonStyle(PillButtonStyle(tint: Theme.positive, isSelected: habit.completedToday))
                    Button("Missed") { setCompleted(false, daysAgo: 0) }
                        .buttonStyle(PillButtonStyle(tint: Theme.negative, isSelected: !habit.completedToday))
                    Button("Done Yesterday") { setCompleted(true, daysAgo: 1) }
                        .buttonStyle(PillButtonStyle(tint: Theme.muted))
                        .disabled(!habit.canCompleteYesterday)
                }
                HStack(spacing: 8) {
                    Button("Edit Habit") { isEditing = true }
                        .buttonStyle(PillButtonStyle(tint: Theme.muted))
                    Button("Delete Habit", role: .destructive) { isConfirmingDelete = true }
                        .buttonStyle(PillButtonStyle(tint: Theme.danger))
                }
            }
            .padding(.top, 2)

            Text(habit.details)
                .sansFont(12)
                .foregroundStyle(Theme.textSecondary)
                // Sidebar lists limit text to one line by default; show all of it.
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.top, 4)
        }
        .padding(.top, 8)
        .sheet(isPresented: $isEditing) {
            EditHabitView(habit: habit)
        }
        .confirmationDialog(
            "Delete “\(habit.name)”?",
            isPresented: $isConfirmingDelete
        ) {
            Button("Delete Habit", role: .destructive, action: deleteHabit)
        } message: {
            Text("The habit and its whole history will be removed. This can't be undone.")
        }
    }

    /// Done / Missed (today) and Done Yesterday.
    private func setCompleted(_ completed: Bool, daysAgo: Int) {
        // Make sure today has an entry, e.g. if the app stayed open past midnight.
        habit.fillMissingDays()
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        withAnimation {
            _ = habit.setCompleted(completed, on: date)
        }
        try? modelContext.save()
    }

    private func deleteHabit() {
        withAnimation {
            modelContext.delete(habit)
        }
        try? modelContext.save()
    }

    /// Name and short name on the left, value and change on the right,
    /// like a ticker row in Stocks.
    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .sansFont(15, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text(habit.tickerLabel)
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

/// The change in percent, as a pill in the same colors as the Done
/// (gain) and Missed (loss) buttons.
struct ChangeBadge: View {
    let changePercent: Double

    var body: some View {
        Text("\(changePercent >= 0 ? "+" : "")\(changePercent, specifier: "%.2f")%")
            .font(.mono(12, weight: .medium))
            .monospacedDigit()
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .frame(minWidth: 64, alignment: .trailing)
            .pillBackground(tint: Theme.trendColor(forChange: changePercent))
    }
}

extension View {
    /// Liquid Glass buttons. A highlighted button (e.g. "Done" when the habit
    /// is completed today) is filled with the tint color. Button labels use
    /// the regular font, not the app-wide monospaced one.
    func habitButtonStyle(highlighted: Bool = false, tint: Color? = nil) -> some View {
        Group {
            if highlighted {
                buttonStyle(.glassProminent)
                    .tint(tint)
                    .foregroundStyle(.black)
            } else {
                buttonStyle(.glass)
            }
        }
        .fontDesign(.default)
    }
}

#Preview {
    let container = DummyData.previewContainer
    List(DummyData.previewHabits(in: container)) { habit in
        HabitRowView(habit: habit, currency: AppConfig.currency)
    }
    .listStyle(.sidebar)
    .frame(width: 340, height: 600)
    .modelContainer(container)
}
