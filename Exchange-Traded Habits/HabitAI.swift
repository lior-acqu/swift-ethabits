//
//  HabitAI.swift
//  Exchange-Traded Habits
//
//  Apple Intelligence features, using the on-device model from Apple's
//  Foundation Models framework: analyzing the habit data and suggesting
//  new habits. Everything runs on this Mac; nothing is sent to a server.
//
//  Roughly like calling an LLM API with "structured output" in Node: each
//  @Generable struct below is the response schema, and the model is
//  constrained to fill it in, so we get Swift values back instead of JSON.
//

import Foundation
import FoundationModels

// MARK: - Response types

/// An analysis of the user's habit data.
@Generable
nonisolated struct HabitAnalysis: Equatable {
    @Guide(description: "Two or three sentences on how the habits are going overall. Address the user as 'you'.")
    var summary: String

    @Guide(description: "What is going well. Each item is one short sentence that names a habit and the number behind it.", .maximumCount(3))
    var strengths: [String]

    @Guide(description: "Where the user is struggling. Each item is one short sentence that names a habit and the number behind it. Only include habits marked 'behind' or 'slightly behind', never ones marked 'on track'.", .maximumCount(3))
    var struggles: [String]

    @Guide(description: "Concrete, practical tips that fit the data. One sentence each.", .maximumCount(3))
    var tips: [String]
}

/// A suggested new habit, in the same shape as the Add Habit form.
@Generable
nonisolated struct HabitSuggestion: Equatable {
    @Guide(description: "A short habit name of one to three words, e.g. 'Evening Walk'.")
    var name: String

    @Guide(description: "The cue that triggers the habit. It completes the sentence \"I'll complete this habit when …\" and is lowercase, e.g. 'I finish lunch'.")
    var time: String

    @Guide(description: "Who the user becomes through the habit. It completes the sentence \"… to become …\" and is lowercase, e.g. 'a more relaxed person'.")
    var identity: String

    @Guide(description: "How important the habit is for the user's goal, from 1 to 10.", .range(1...10))
    var importance: Int

    @Guide(description: "How hard the habit will be to stick to, from 1 to 10.", .range(1...10))
    var difficulty: Int

    @Guide(description: "Repeat every this many days. 1 means daily, 7 means weekly. Use 1 for small everyday habits; use more only when the habit is naturally less frequent.", .range(1...30))
    var interval: Int

    @Guide(description: "One sentence on why this habit helps with the user's problem.")
    var reason: String
}

/// A list of suggested new habits.
@Generable
nonisolated struct HabitSuggestions: Equatable {
    @Guide(description: "Three different habits that address the user's problem.", .count(3))
    var habits: [HabitSuggestion]
}

// MARK: - Requests

enum HabitAI {
    /// The on-device Apple Intelligence model.
    static var model: SystemLanguageModel { .default }

    /// Why the model can't be used right now, or nil if it is ready.
    /// Like feature-detecting a browser API before using it.
    static var unavailableReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This Mac doesn't support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in System Settings to use these features."
        case .unavailable(.modelNotReady):
            return "Apple Intelligence is still getting ready (the model may be downloading). Try again in a few minutes."
        case .unavailable:
            return "Apple Intelligence isn't available right now."
        }
    }

    /// Limits each answer's length. Without it, the small model sometimes
    /// keeps generating until it overflows its context window.
    private static let options = GenerationOptions(maximumResponseTokens: 1000)

    private static let coachInstructions = """
        You are a friendly, practical habit coach inside a habit tracker app. \
        In the app, every habit has a value like a stock: it grows 1% on days the habit is done \
        and shrinks a little on days it is not. Habits with an interval of N days are only expected \
        about once every N days. Base everything on the data you are given, mention habits by name, \
        and keep the language simple and encouraging. Never invent numbers. \
        Don't put quotation marks around habit names.
        """

    /// Analyzes the user's habit data.
    static func analyze(habits: [Habit], statistics: HabitStatistics) async throws -> HabitAnalysis {
        let session = LanguageModelSession(instructions: coachInstructions)
        let prompt = """
            Analyze my habit data and tell me how I'm doing.

            \(makeSummary(habits: habits, statistics: statistics))
            """
        return try await session.respond(to: prompt, generating: HabitAnalysis.self, options: options).content
    }

    /// Suggests new habits for a problem the user describes.
    static func suggestHabits(for problem: String, habits: [Habit]) async throws -> [HabitSuggestion] {
        let session = LanguageModelSession(instructions: coachInstructions + """
             Suggest small, specific habits that are easy to start, each tied to a clear cue \
            from the user's day. Don't suggest habits the user already has.
            """)
        let existing = habits.isEmpty ? "none" : habits.map(\.name).joined(separator: ", ")
        let prompt = """
            My problem: \(problem)

            Habits I already track: \(existing)

            Suggest three new habits that help with my problem.
            """
        let suggestions = try await session.respond(to: prompt, generating: HabitSuggestions.self, options: options).content.habits
        return suggestions.map { suggestion in
            var cleaned = suggestion
            cleaned.name = cleanName(suggestion.name)
            cleaned.time = cleanPhrase(suggestion.time, droppingPrefixes: ["I'll complete this habit when", "when"])
            cleaned.identity = cleanPhrase(suggestion.identity, droppingPrefixes: ["to become", "become"])
            return cleaned
        }
    }

    // MARK: - Cleaning up the model's phrases

    /// Trims a generated name and removes surrounding quotes or a final period.
    static func cleanName(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'“”.")))
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    /// Makes a generated phrase fit into the habit statement
    /// "I'll complete this habit when <time> to become <identity>.":
    /// no final period, no repeated lead-in words, "I" capitalized, and
    /// nothing after a repeated "to become" (the model sometimes adds one).
    static func cleanPhrase(_ text: String, droppingPrefixes prefixes: [String]) -> String {
        var phrase = text.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'“”")))
        for prefix in prefixes where phrase.lowercased().hasPrefix(prefix.lowercased() + " ") {
            phrase = String(phrase.dropFirst(prefix.count + 1))
        }
        if let repeated = phrase.range(of: " to become", options: .caseInsensitive) {
            phrase = String(phrase[..<repeated.lowerBound])
        }
        while let last = phrase.last, ".!,;".contains(last) {
            phrase.removeLast()
        }
        // "i" on its own → "I", e.g. "i put on my shoes".
        phrase = phrase.split(separator: " ", omittingEmptySubsequences: false)
            .map { $0 == "i" ? "I" : $0 == "i'm" ? "I'm" : String($0) }
            .joined(separator: " ")
        // Lowercase the first letter unless it's "I", since the phrase sits mid-sentence.
        if let first = phrase.first, !phrase.hasPrefix("I ") && !phrase.hasPrefix("I'") && phrase != "I" {
            phrase = first.lowercased() + phrase.dropFirst()
        }
        return phrase.trimmingCharacters(in: .whitespaces)
    }

    /// A friendly message for an error from the model.
    static func message(for error: Error) -> String {
        let description = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return "Apple Intelligence couldn't answer this time. \(description)"
    }

    // MARK: - Data summary

    /// How many recent days the summary looks at. The on-device model has a
    /// small context window (a few thousand tokens), so we send a compact
    /// text digest instead of every log entry.
    static let recentDays = 30

    /// A short text description of all habits and the overall statistics.
    static func makeSummary(habits: [Habit], statistics: HabitStatistics) -> String {
        var lines = ["Habits (\(habits.count)):"]
        lines += habits.map { "- " + habitLine($0) }

        lines.append("")
        lines.append("Overall:")
        lines.append("- Tracking for \(statistics.daysTracking) days.")
        if let rate = statistics.completionRate {
            lines.append("- \(Int(rate.rounded()))% of all daily habit entries were done.")
        }
        if let growth = statistics.averageDailyGrowth {
            lines.append("- The total portfolio grows on average \(growth.formatted(.number.precision(.fractionLength(2))))% per day.")
        }
        lines.append("- Current streak without a losing day: \(days(statistics.currentStreak)) (longest: \(days(statistics.longestStreak))).")
        lines.append("- Days with every habit done: \(statistics.perfectDays).")
        if let weekday = statistics.bestWeekday {
            lines.append("- Best weekday: \(weekday.label) (\(Int(weekday.percent.rounded()))% done).")
        }
        if let consistent = statistics.mostConsistent {
            lines.append("- Most consistent habit: \(consistent.name).")
        }
        return lines.joined(separator: "\n")
    }

    private static func days(_ count: Int) -> String {
        "\(count) day\(count == 1 ? "" : "s")"
    }

    /// How a habit did over the last `recentDays` finished days: how many
    /// days were tracked, how often it was done and how often it should
    /// have been, given its interval.
    static func recentRecord(_ habit: Habit) -> (days: Int, done: Int, expected: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let since = calendar.date(byAdding: .day, value: -recentDays, to: today)!
        // Finished days only: today isn't over yet.
        let recent = habit.sortedLogs.filter { !$0.isStartingEntry && $0.date >= since && $0.date < today }
        let done = recent.filter(\.completed).count
        let expected = max(Int((Double(recent.count) / habit.interval).rounded()), recent.isEmpty ? 0 : 1)
        return (recent.count, done, expected)
    }

    /// One habit as a line of text, with its recent track record.
    static func habitLine(_ habit: Habit) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let (tracked, done, expected) = recentRecord(habit)

        // Days since it was last done (counting back from yesterday).
        let lastDone = habit.sortedLogs.last { $0.completed && !$0.isStartingEntry && $0.date < today }
        let daysSinceDone = lastDone.flatMap { calendar.dateComponents([.day], from: $0.date, to: today).day }

        let interval = habit.interval == 1 ? "daily" : "every \(habit.interval.formatted()) days"
        // Spell out the verdict, so the small model doesn't have to compare numbers.
        let status = done >= expected ? "on track" : done * 3 >= expected * 2 ? "slightly behind" : "behind"
        var parts = [
            // No quotes around the name: the model copies them, and a quote
            // mark ends the text early in structured output.
            "\(habit.name) (\(interval)): \(habit.details)",
            "Last \(tracked) days: done \(done) times, goal about \(expected) times, so \(status).",
            "Value change since start: \(habit.changePercent >= 0 ? "+" : "")\(habit.changePercent.formatted(.number.precision(.fractionLength(1))))%.",
        ]
        if let daysSinceDone {
            parts.append("Last done \(days(daysSinceDone)) ago.")
        } else {
            parts.append("Not done yet.")
        }
        if habit.completedToday { parts.append("Done today.") }
        return parts.joined(separator: " ")
    }
}
