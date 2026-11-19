//
//  AddHabitView.swift
//  Exchange-Traded Habits
//
//  The Add Habit form, shown as a sheet. A port of the form on the old
//  index.html and the `/add` route in app.py.
//

import SwiftData
import SwiftUI

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // @State is SwiftUI's useState: each field's current value.
    @State private var name = ""
    @State private var time = ""
    @State private var identity = ""
    @State private var importance = 5
    @State private var difficulty = 5
    @State private var interval = 1.0
    @State private var errorMessage: String?

    /// Opens the form empty, or filled in with an Apple Intelligence
    /// suggestion. Nothing is saved until "Add Habit" is pressed.
    init(prefill suggestion: HabitSuggestion? = nil) {
        guard let suggestion else { return }
        _name = State(initialValue: suggestion.name)
        _time = State(initialValue: suggestion.time)
        _identity = State(initialValue: suggestion.identity)
        _importance = State(initialValue: suggestion.importance)
        _difficulty = State(initialValue: suggestion.difficulty)
        _interval = State(initialValue: Double(suggestion.interval))
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmed(name).isEmpty && !trimmed(time).isEmpty && !trimmed(identity).isEmpty && interval > 0
    }

    /// The live "Every X day/s, I'll complete this habit when X to become X." line.
    private var statement: String {
        Habit.makeDetails(
            interval: interval,
            time: trimmed(time).isEmpty ? "X" : trimmed(time),
            identity: trimmed(identity).isEmpty ? "X" : trimmed(identity)
        )
    }

    private var startingValue: Double {
        guard interval > 0 else { return 0 }
        return Habit.makeInitialValue(importance: importance, difficulty: difficulty, interval: interval)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add Habit")
                .sansFont(20, weight: .semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Form {
                Section {
                    TextField("Habit Name", text: $name, prompt: Text("e.g. Morning Run"))
                    TextField("When", text: $time, prompt: Text("I'll always complete the habit when …"))
                    TextField("Identity", text: $identity, prompt: Text("By doing this habit, I'll become …"))
                }

                Section {
                    LabeledContent {
                        NumberStepper(value: $importance)
                    } label: {
                        Text("Importance")
                        Text("How important is this habit to me?")
                    }
                    LabeledContent {
                        NumberStepper(value: $difficulty)
                    } label: {
                        Text("Difficulty")
                        Text("How hard has it been to make this habit stick?")
                    }
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
                    Text("Starting value: \(AppConfig.currency) \(startingValue, specifier: "%.2f")  ·  Importance · Difficulty · (ln(Interval) + 1)")
                        .font(.mono(11))
                        .foregroundStyle(.secondary)
                }

                Section("Your Statement") {
                    Text(statement)
                        .italic()
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520)
        .toolbar {
            // In a sheet, macOS places these at the bottom right.
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .fontDesign(.default)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add Habit", action: addHabit)
                    .fontDesign(.default)
                    .disabled(!isValid)
            }
        }
        .alert("Could Not Add Habit", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func addHabit() {
        guard isValid else { return }
        do {
            try Habit.create(
                name: trimmed(name), time: trimmed(time), identity: trimmed(identity),
                importance: importance, difficulty: difficulty, interval: interval,
                in: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// A number from 1 to 10 with a stepper next to it.
private struct NumberStepper: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .monospacedDigit()
                .frame(minWidth: 20, alignment: .trailing)
            Stepper("Value", value: $value, in: 1...10)
                .labelsHidden()
        }
    }
}

#Preview {
    AddHabitView()
        .modelContainer(DummyData.previewContainer)
}
