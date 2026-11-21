//
//  PillButton.swift
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

    func body(content: Content) -> some View {
        let shape = Capsule()
        content
            .foregroundStyle(tint.mix(with: .white, by: 0.72))
            .background(tint.opacity(0.22), in: shape)
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

/// A capsule button in the sidebar style:
/// `PillButton("Done", tint: Theme.positive, isSelected: true) { … }`.
///
/// The look is applied to this view, not inside a ButtonStyle. SwiftUI
/// doesn't always re-apply a ButtonStyle when only the style's own
/// properties change (like `isSelected`), which left Done/Missed showing
/// the old selection after the first click. A plain view always updates
/// when its inputs change, like a React component with new props.
struct PillButton: View {
    let title: String
    let tint: Color
    var isSelected = false
    var role: ButtonRole?
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    init(_ title: String, tint: Color, isSelected: Bool = false, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.isSelected = isSelected
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Text(title)
                .sansFont(13)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .contentShape(Capsule())
        }
        .buttonStyle(PressFeedbackStyle(tint: tint))
        .modifier(PillBackground(tint: tint, isSelected: isSelected, isHovered: isHovered && isEnabled))
        .opacity(isEnabled ? 1 : 0.4)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

/// Only the pressed effect: a slightly stronger fill while the mouse is
/// down. It depends on nothing but the press itself, so it can't go stale.
private struct PressFeedbackStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(tint.opacity(configuration.isPressed ? 0.14 : 0), in: Capsule())
    }
}
