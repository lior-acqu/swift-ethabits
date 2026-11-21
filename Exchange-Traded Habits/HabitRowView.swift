//
//  HabitRowView.swift
//  Exchange-Traded Habits
//
//  One habit in the sidebar: title, short name, value, change,
//  buttons and description.
//

import SwiftData
import SwiftUI

/// What a sidebar row shows, read from the habit as plain values.
///
/// ContentView builds these in its body, so they are re-read on every
/// change and passed down like props in React. A row that only observed
/// its Habit object by itself sometimes missed the first change after
/// launch (the chart updated, the row didn't).
struct HabitRowModel: Identifiable {
    let habit: Habit
    let name: String
    let tickerLabel: String
    let details: String
    let currentValue: Double
    let changePercent: Double
    let completedToday: Bool
    let canCompleteYesterday: Bool

    /// The habit object itself. Its persistentModelID would change on its
    /// first save, which would make the list treat it as a new row.
    var id: ObjectIdentifier { ObjectIdentifier(habit) }

    init(_ habit: Habit) {
        self.habit = habit
        name = habit.name
        tickerLabel = habit.tickerLabel
        details = habit.details
        currentValue = habit.currentValue
        changePercent = habit.changePercent
        completedToday = habit.completedToday
        canCompleteYesterday = habit.canCompleteYesterday
    }
}

struct HabitRowView: View {
    let row: HabitRowModel
    let currency: String

    /// The habit to change when a button is pressed. Everything shown
    /// comes from `row` instead.
    private var habit: Habit { row.habit }

    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    PillButton("Done", tint: Theme.positive, isSelected: row.completedToday) {
                        setCompleted(true, daysAgo: 0)
                    }
                    PillButton("Missed", tint: Theme.negative, isSelected: !row.completedToday) {
                        setCompleted(false, daysAgo: 0)
                    }
                    PillButton("Done Yesterday", tint: Theme.muted) { setCompleted(true, daysAgo: 1) }
                        .disabled(!row.canCompleteYesterday)
                }
                HStack(spacing: 8) {
                    PillButton("Edit Habit", tint: Theme.muted) { isEditing = true }
                    PillButton("Delete Habit", tint: Theme.danger, role: .destructive) { isConfirmingDelete = true }
                }
            }
            .padding(.top, 2)

            Text(row.details)
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
            "Delete “\(row.name)”?",
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
                Text(row.name)
                    .sansFont(15, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text(row.tickerLabel)
                    .font(.mono(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .lineLimit(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currency) \(row.currentValue, specifier: "%.2f")")
                    .font(.mono(15, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                ChangeBadge(changePercent: row.changePercent)
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
        HabitRowView(row: HabitRowModel(habit), currency: AppConfig.currency)
    }
    .listStyle(.sidebar)
    .frame(width: 340, height: 600)
    .modelContainer(container)
}
