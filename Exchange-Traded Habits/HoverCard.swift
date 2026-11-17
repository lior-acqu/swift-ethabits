//
//  HoverCard.swift
//  Exchange-Traded Habits
//
//  The small card shown while hovering over the graph or the heatmap:
//  the day as the title, a value below it.
//

import SwiftUI

struct HoverCard: View {
    let date: Date
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.mono(13))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.mono(24, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        .fixedSize()
        // Purely informative: never steal the mouse from the graph or heatmap.
        .allowsHitTesting(false)
    }
}

#Preview {
    HoverCard(date: .now, value: "CHF 410.94")
        .padding(40)
        .background(Color(white: 0.85))
}
