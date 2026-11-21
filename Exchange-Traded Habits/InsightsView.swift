//
//  InsightsView.swift
//  Exchange-Traded Habits
//
//  The Apple Intelligence panel on the right: analyze the habit data and
//  suggest new habits for a problem. Nothing runs until a button is
//  pressed, and suggestions only open a pre-filled form, so nothing
//  changes without the user confirming.
//

import SwiftData
import SwiftUI

struct InsightsView: View {
    let habits: [Habit]

    /// Where a request stands, like a small `useState` state machine for a fetch.
    private enum RequestState: Equatable {
        case idle
        case running
        case failed(String)

        var isRunning: Bool { self == .running }
    }

    /// Wraps a value so it can drive `.sheet(item:)`, which needs an `id`.
    private struct SheetItem<Value>: Identifiable {
        let id = UUID()
        let value: Value
    }

    // Analysis
    @State private var analysis: HabitAnalysis?
    @State private var analysisState = RequestState.idle

    // New habits
    @State private var newHabitProblem = ""
    @State private var suggestions: [HabitSuggestion] = []
    @State private var suggestionsState = RequestState.idle
    @State private var addSheet: SheetItem<HabitSuggestion>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if let reason = HabitAI.unavailableReason {
                    ContentUnavailableView(
                        "Apple Intelligence Unavailable",
                        systemImage: "apple.intelligence",
                        description: Text(reason)
                    )
                    .fontDesign(.default)
                } else {
                    analysisSection
                    Divider()
                    newHabitsSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(item: $addSheet) { item in
            AddHabitView(prefill: item.value)
        }
    }

    // MARK: - Analysis

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            header("Analysis", "A look at how your habits are going, based on the last \(HabitAI.recentDays) days.")
            runButton(analysis == nil ? "Analyze" : "Analyze Again", state: analysisState, action: analyze)
                .disabled(habits.isEmpty)
            errorText(analysisState)

            if let analysis {
                VStack(alignment: .leading, spacing: 14) {
                    prose(analysis.summary, color: Theme.textPrimary)
                    bulletList("Going Well", analysis.strengths, icon: "arrow.up.right", color: Theme.positive)
                    bulletList("Needs Attention", analysis.struggles, icon: "arrow.down.right", color: Theme.negative)
                    bulletList("Tips", analysis.tips, icon: "lightbulb", color: Theme.neutral)
                }
            }
        }
    }

    private func analyze() {
        analysisState = .running
        // Task { } runs async work from a button, like calling an async
        // function from an onPress handler in React Native.
        Task {
            do {
                analysis = try await HabitAI.analyze(habits: habits, statistics: HabitStatistics(habits: habits))
                analysisState = .idle
            } catch {
                analysisState = .failed(HabitAI.message(for: error))
            }
        }
    }

    // MARK: - New habits

    private var newHabitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            header("Suggest New Habits", "Describe a problem or a goal, and get three habits that could help.")
            problemField($newHabitProblem, prompt: "e.g. I feel stressed after work and sleep badly.")
            runButton("Suggest Habits", state: suggestionsState, action: suggestHabits)
                .disabled(trimmed(newHabitProblem).isEmpty)
            errorText(suggestionsState)

            ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                suggestionCard(suggestion)
            }
        }
    }

    private func suggestionCard(_ suggestion: HabitSuggestion) -> some View {
        let interval = Double(suggestion.interval)
        let startValue = Habit.makeInitialValue(
            importance: suggestion.importance, difficulty: suggestion.difficulty, interval: interval
        )
        return card {
            Text(suggestion.name)
                .sansFont(14, weight: .semibold)
                .foregroundStyle(Theme.textPrimary)
            prose(Habit.makeDetails(interval: interval, time: suggestion.time, identity: suggestion.identity))
            Text("Importance \(suggestion.importance) · Difficulty \(suggestion.difficulty) · \(AppConfig.currency) \(startValue, specifier: "%.2f")")
                .font(.mono(11))
                .foregroundStyle(Theme.textSecondary)
            prose(suggestion.reason, italic: true)
            Button("Add…", systemImage: "plus") {
                addSheet = SheetItem(value: suggestion)
            }
            .habitButtonStyle()
            .controlSize(.small)
        }
    }

    private func suggestHabits() {
        suggestionsState = .running
        Task {
            do {
                suggestions = try await HabitAI.suggestHabits(for: trimmed(newHabitProblem), habits: habits)
                suggestionsState = .idle
            } catch {
                suggestionsState = .failed(HabitAI.message(for: error))
            }
        }
    }

    // MARK: - Building blocks

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func header(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .sansFont(17, weight: .semibold)
                .foregroundStyle(Theme.textPrimary)
            prose(subtitle)
        }
    }

    /// Running text in the regular font, like the habit descriptions.
    private func prose(_ text: String, color: Color = Theme.textSecondary, italic: Bool = false) -> some View {
        // Italic goes on the Text itself: .italic() on the finished view
        // would reset the font design to the app-wide monospaced one.
        Text(text)
            .italic(italic)
            .sansFont(13)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func problemField(_ text: Binding<String>, prompt: String) -> some View {
        TextField("Problem", text: text, prompt: Text(prompt), axis: .vertical)
            .labelsHidden()
            .lineLimit(2...5)
            .textFieldStyle(.roundedBorder)
    }

    /// A prominent glass button with a spinner next to it while running.
    private func runButton(_ title: String, state: RequestState, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Button(title, systemImage: "sparkles", action: action)
                .habitButtonStyle(highlighted: true, tint: Theme.positive)
                .disabled(state.isRunning)
            if state.isRunning {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func errorText(_ state: RequestState) -> some View {
        if case .failed(let message) = state {
            prose(message, color: Theme.negative)
        }
    }

    private func bulletList(_ title: String, _ items: [String], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !items.isEmpty {
                Text(title)
                    .sansFont(13, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(color)
                        prose(item)
                    }
                }
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let container = DummyData.previewContainer
    InsightsView(habits: DummyData.previewHabits(in: container))
        .frame(width: 360, height: 900)
        .background(Theme.background)
        .modelContainer(container)
}
