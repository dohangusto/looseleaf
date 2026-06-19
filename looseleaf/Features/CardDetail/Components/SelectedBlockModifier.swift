import SwiftUI

/// Lifts a special block above the paper when it is selected/being edited,
/// using a stronger-than-default shadow to communicate active focus.
struct SelectedBlockModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .shadow(
                color: .black.opacity(isSelected ? 0.28 : 0.0),
                radius: isSelected ? 22 : 0,
                x: 0,
                y: isSelected ? 12 : 0
            )
            .scaleEffect(isSelected ? 1.015 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

extension View {
    /// Applies the active/selected depth treatment when `isSelected` is true.
    func selectedBlock(_ isSelected: Bool) -> some View {
        modifier(SelectedBlockModifier(isSelected: isSelected))
    }
}
