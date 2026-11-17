//
//  ContentView.swift
//  Exchange-Traded Habits
//
//  The main window: the habits in a glass sidebar on the left,
//  the portfolio graph on the right.
//

import SwiftUI

struct ContentView: View {
    // Dummy data for now; later this comes from local storage.
    private let habits = DummyData.habits
    private let currency = DummyData.currency

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
            ScrollView {
                PortfolioChartView(
                    history: DummyData.portfolioHistory(for: habits),
                    currency: currency
                )
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
                .frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
            .background {
                // Fill the whole detail area, including the space under the
                // toolbar and behind the glass sidebar.
                Theme.background
                    .ignoresSafeArea()
                    .backgroundExtensionEffect()
            }
        }
        .toolbar(removing: .title)
        .frame(minWidth: 820, minHeight: 520)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
