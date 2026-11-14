//
//  ContentView.swift
//  Exchange-Traded Habits
//
//  The main page: the portfolio graph on top, the habit entries in a grid below.
//

import SwiftUI

struct ContentView: View {
    // Dummy data for now; later this comes from local storage.
    private let habits = DummyData.habits
    private let currency = DummyData.currency

    /// As many columns as fit, each at least 330 wide
    /// (CSS: `grid-template-columns: repeat(auto-fill, minmax(330px, 1fr))`).
    private let columns = [GridItem(.adaptive(minimum: 330), spacing: 50, alignment: .top)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                PortfolioChartView(
                    history: DummyData.portfolioHistory(for: habits),
                    currency: currency
                )

                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    ForEach(habits) { habit in
                        HabitCardView(habit: habit, currency: currency)
                    }
                }
            }
            .frame(maxWidth: 1000)
            .padding(.horizontal, 40)
            .padding(.vertical, 50)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .frame(minWidth: 460, minHeight: 500)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
