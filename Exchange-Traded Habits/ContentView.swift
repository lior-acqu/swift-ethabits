//
//  ContentView.swift
//  Exchange-Traded Habits
//
//  The main window: the habits in a glass sidebar on the left,
//  the portfolio graph on the right.
//

import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
    /// All stored habits, oldest first. Updates automatically when one is added.
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var isAddingHabit = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    private let currency = AppConfig.currency

    var body: some View {
        // NavigationSplitView is macOS's sidebar + content layout. On macOS 26
        // the sidebar automatically becomes a floating Liquid Glass panel.
        NavigationSplitView {
            List(habits) { habit in
                HabitRowView(habit: habit, currency: currency)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 300, ideal: 340, max: 460)
        } detail: {
            detail
                .background {
                    // Fill the whole detail area, including the space under the
                    // toolbar and behind the glass sidebar.
                    Theme.background
                        .ignoresSafeArea()
                        .backgroundExtensionEffect()
                }
                .toolbar {
                    // On macOS, .primaryAction sits at the leading edge. A
                    // flexible spacer (like `flex: 1` in CSS) pushes the
                    // button to the top-right corner instead.
                    ToolbarSpacer(.flexible)
                    // Toolbar buttons get the Liquid Glass look automatically.
                    ToolbarItem {
                        Button("Add Habit", systemImage: "plus") { isAddingHabit = true }
                            .help("Add Habit")
                    }
                }
        }
        .toolbar(removing: .title)
        // Monospaced text everywhere by default, like setting `font-family`
        // on <body>. Titles, habit names and descriptions opt out with .sansFont.
        // Applied above .sheet so the Add/Edit sheets inherit it too.
        .fontDesign(.monospaced)
        .sheet(isPresented: $isAddingHabit) {
            AddHabitView()
        }
        // Keep the daily entries up to date: when the app comes back to the
        // front, and at midnight while it is open.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { HabitTracker.fillMissingDays(in: modelContext) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            HabitTracker.fillMissingDays(in: modelContext)
        }
        .frame(minWidth: 820, minHeight: 520)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var detail: some View {
        if habits.isEmpty {
            ContentUnavailableView {
                Label("No Habits Yet", systemImage: "chart.line.uptrend.xyaxis")
            } description: {
                Text("Press + to add your first habit.")
            }
        } else {
            ScrollView {
                // Computed once per update and shared by both sections below.
                let statistics = HabitStatistics(habits: habits)

                VStack(alignment: .leading, spacing: 50) {
                    PortfolioChartView(history: habits.portfolioHistory(), currency: currency)
                    StatisticsView(statistics: statistics, currency: currency)
                    CompletionHeatmapView(completionByDay: statistics.completionByDay)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
                .frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(DummyData.previewContainer)
}
