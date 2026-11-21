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

    /// The panels that can slide in on the right. Only one is open at a time.
    private enum SidePanel {
        case insights, settings
    }

    @State private var openPanel: SidePanel?

    /// The width of the main area, measured to decide whether the open
    /// panel fits next to the content or has to float over it.
    @State private var detailWidth: CGFloat = 0

    private let panelWidth: CGFloat = 360
    /// The narrowest the main content may get before the panel overlays it.
    private let minContentWidth: CGFloat = 480

    /// True when the panel can sit next to the content; false when the
    /// window is too narrow and the panel floats over the content instead.
    private var panelFitsBeside: Bool {
        detailWidth - panelWidth >= minContentWidth
    }

    // Settings, saved in UserDefaults (see AppSettings.swift).
    @AppStorage(AppSettings.aiEnabledKey) private var aiEnabled = AppSettings.aiEnabledDefault
    @AppStorage(AppSettings.currencyKey) private var currencySetting = AppSettings.defaultCurrency

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    /// The currency label, updated live while it is edited in Settings.
    private var currency: String { AppSettings.currency(from: currencySetting) }

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
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { detailWidth = $0 }
                // The Insights or Settings panel: a floating glass panel on
                // the right, like the sidebar on the left. Unlike the system
                // inspector, it never needs extra window width, so it can't
                // push the layout out of a small window.
                .overlay(alignment: .trailing) {
                    if let openPanel {
                        Group {
                            switch openPanel {
                            case .insights: InsightsView(habits: habits)
                            case .settings: SettingsView()
                            }
                        }
                        .frame(width: panelWidth)
                        .frame(maxHeight: .infinity)
                        .glassEffect(.regular, in: .rect(cornerRadius: 22))
                        .padding(8)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                // Turning Apple Intelligence off in Settings removes the
                // Insights panel along with its button.
                .onChange(of: aiEnabled) { _, isEnabled in
                    if !isEnabled && openPanel == .insights { toggle(.insights) }
                }
                .toolbar {
                    // On macOS, .primaryAction sits at the leading edge. A
                    // flexible spacer (like `flex: 1` in CSS) pushes the
                    // buttons to the top-right corner instead.
                    ToolbarSpacer(.flexible)
                    // Toolbar buttons get the Liquid Glass look automatically.
                    ToolbarItem {
                        Button("Add Habit", systemImage: "plus") { isAddingHabit = true }
                            .help("Add Habit")
                    }
                    if aiEnabled {
                        ToolbarItem {
                            Button("Insights", systemImage: "sparkles") { toggle(.insights) }
                                .help("Apple Intelligence Insights")
                        }
                    }
                    ToolbarItem {
                        Button("Settings", systemImage: "gearshape") { toggle(.settings) }
                            .help("Settings (⌘,)")
                            .keyboardShortcut(",", modifiers: .command)
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

    /// Opens a panel, closes it if it is already open, or switches to it
    /// if the other one is open.
    private func toggle(_ panel: SidePanel) {
        withAnimation(.smooth(duration: 0.3)) {
            openPanel = openPanel == panel ? nil : panel
        }
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
                // Make room for the Insights panel when it fits beside the
                // content (like a CSS margin); otherwise it floats on top.
                .padding(.trailing, openPanel != nil && panelFitsBeside ? panelWidth + 16 : 0)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(DummyData.previewContainer)
}
