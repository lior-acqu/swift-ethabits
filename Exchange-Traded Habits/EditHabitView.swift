//
//  EditHabitView.swift
//  Exchange-Traded Habits
//
//  The Edit Habit form, shown as a sheet. A port of edit.html and the
//  `/edit` route in the old app.py.
//

import SwiftData
import SwiftUI

struct EditHabitView: View {
    let habit: Habit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // The form starts with the habit's current values; nothing is changed
    // until "Save Changes" is pressed.
    @State private var name: String
    @State private var shortName: String
    @State private var initialValue: Double
    @State private var interval: Double
    @State private var details: String

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _shortName = State(initialValue: habit.shortName)
        _initialValue = State(initialValue: habit.initialValue)
        _interval = State(initialValue: habit.interval)
        _details = State(initialValue: habit.details)
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmed(name).isEmpty && !trimmed(shortName).isEmpty && !trimmed(details).isEmpty
            && initialValue > 0 && initialValue <= 1000
            && interval > 0 && interval <= 365
    }

    /// What the current value would become with the new starting value.
    private var previewValue: Double {
        guard habit.initialValue > 0 else { return 0 }
        return habit.currentValue / habit.initialValue * initialValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Edit Habit")
                .sansFont(20, weight: .semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Form {
                Section {
                    TextField("Habit Name", text: $name, prompt: Text("Habit Name"))
                    TextField("Short Name", text: $shortName, prompt: Text("e.g. MRNN"))
                }

                Section {
                    LabeledContent {
                        HStack(spacing: 6) {
                            TextField("Start Value", value: $initialValue, format: .number.precision(.fractionLength(0...2)))
                                .labelsHidden()
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(AppConfig.currency)
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        Text("Start Value")
                        Text("Between 0 and 1000")
                    }
                } footer: {
                    Text("All past values scale with it, so the change in % stays the same. Current value becomes \(AppConfig.currency) \(previewValue, specifier: "%.2f").")
                        .font(.mono(11))
                        .foregroundStyle(.secondary)
                }

                Section {
                    LabeledContent {
                        HStack(spacing: 6) {
                            TextField("Interval", value: $interval, format: .number)
                                .labelsHidden()
                                .multilineTextAlignment(.trailing)
                                .frame(width: 56)
                            Text("day/s")
                                .foregroundStyle(.secondary)
                            Stepper("Interval", value: $interval, in: 1...365, step: 1)
                                .labelsHidden()
                        }
                    } label: {
                        Text("Repeat Every")
                        Text("Daily = 1")
                    }
                } footer: {
                    Text("Past values stay the same. From now on, a missed day costs 1% ÷ \(Habit.formatInterval(max(interval, 0)))\(interval == habit.interval ? "" : " instead of 1% ÷ \(Habit.formatInterval(habit.interval))").")
                        .font(.mono(11))
                        .foregroundStyle(.secondary)
                }
                // Keep "Every X day/s, …" at the start of the description in
                // sync, if the description still starts that way.
                .onChange(of: interval) { oldValue, newValue in
                    let oldPrefix = "Every \(Habit.formatInterval(oldValue)) day/s"
                    guard newValue > 0, details.hasPrefix(oldPrefix) else { return }
                    details = "Every \(Habit.formatInterval(newValue)) day/s" + details.dropFirst(oldPrefix.count)
                }

                Section("Description") {
                    TextField("Description", text: $details, prompt: Text("Description"), axis: .vertical)
                        .labelsHidden()
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .fontDesign(.default)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save Changes", action: save)
                    .fontDesign(.default)
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        guard isValid else { return }
        habit.name = trimmed(name)
        habit.shortName = trimmed(shortName)
        habit.details = trimmed(details)
        habit.setInitialValue(initialValue)
        habit.setInterval(interval)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = DummyData.previewContainer
    EditHabitView(habit: DummyData.previewHabits(in: container)[0])
        .modelContainer(container)
}
