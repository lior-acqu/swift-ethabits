//
//  PillButtonStyle.swift
//  Exchange-Traded Habits
//
//  The capsule buttons and badges in the sidebar: a dark fill in the
//  button's hue, a thin border in the same hue and light tinted text.
//  The border brightens on hover; a selected button (e.g. "Done" when the
//  habit is done today) gets a bright border and a soft glow.
//  Like a styled <button> with :hover and an .is-selected class in CSS.
//

import SwiftUI

/// The shared look of pill buttons and badges.
private struct PillBackground: ViewModifier {
    let tint: Color
    var isSelected = false
    var isHovered = false
    var isPressed = false

    func body(content: Content) -> some View {
        let shape = Capsule()
        content
            .foregroundStyle(tint.mix(with: .white, by: 0.72))
            .background(tint.opacity(isPressed ? 0.34 : 0.22), in: shape)
            .overlay {
                shape.strokeBorder(borderColor, lineWidth: isSelected ? 1.5 : 1)
            }
            .shadow(color: isSelected ? tint.opacity(0.75) : .clear, radius: 7)
    }

    private var borderColor: Color {
        if isSelected { return tint.mix(with: .white, by: 0.6) }
        return tint.opacity(isHovered ? 0.85 : 0.45)
    }
}

extension View {
    /// The pill look without any interaction, e.g. for the change badge.
    func pillBackground(tint: Color) -> some View {
        modifier(PillBackground(tint: tint))
    }
}

/// A capsule button in the sidebar style. Use it like
/// `.buttonStyle(PillButtonStyle(tint: Theme.positive, isSelected: true))`.
struct PillButtonStyle: ButtonStyle {
    let tint: Color
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        PillButton(configuration: configuration, tint: tint, isSelected: isSelected)
    }

    /// A separate view, because hover state needs @State, which a
    /// ButtonStyle itself can't hold.
    private struct PillButton: View {
        let configuration: ButtonStyleConfiguration
        let tint: Color
        let isSelected: Bool

        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .sansFont(13)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .modifier(PillBackground(
                    tint: tint,
                    isSelected: isSelected,
                    isHovered: isHovered && isEnabled,
                    isPressed: configuration.isPressed
                ))
                .opacity(isEnabled ? 1 : 0.4)
                .contentShape(Capsule())
                .onHover { isHovered = $0 }
                .animation(.easeOut(duration: 0.15), value: isHovered)
                .animation(.easeOut(duration: 0.2), value: isSelected)
        }
    }
}
