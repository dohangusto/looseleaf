import SwiftUI

/// Local appearance / accessibility settings for the Card Detail screen.
/// Drives dark mode, font scaling, and contrast intensity.
struct CardDetailVisualSettings {
    var isDarkModeEnabled: Bool = false
    var fontScale: CGFloat = 1.0
    var contrastScale: CGFloat = 1.0

    // MARK: - Colors

    var pageBackground: Color {
        isDarkModeEnabled ? Color(white: 0.07) : Color(.systemBackground)
    }

    var primaryText: Color {
        isDarkModeEnabled ? .white : .primary
    }

    var secondaryText: Color {
        // Higher contrast pulls the secondary text closer to the primary color.
        let lightness = isDarkModeEnabled
            ? 0.72 - 0.12 * (contrastScale - 1.0) * 2
            : 0.0
        return isDarkModeEnabled
            ? Color(white: min(max(lightness, 0.45), 0.85))
            : Color.primary.opacity(min(0.45 + 0.25 * (contrastScale - 1.0) * 2, 0.85))
    }

    var accent: Color { .blue }

    var cardBackground: Color {
        if isDarkModeEnabled {
            // Brighter surface at higher contrast for stronger separation.
            return Color(white: 0.14 + 0.05 * (contrastScale - 1.0) * 2)
        } else {
            return Color(.secondarySystemBackground)
        }
    }

    var amountBoxBackground: Color {
        isDarkModeEnabled ? Color(white: 0.22) : Color(.systemGray6)
    }

    var totalBoxBackground: Color {
        isDarkModeEnabled ? Color(white: 0.40) : Color(.systemGray)
    }

    // MARK: - Contrast-driven borders & depth

    var borderColor: Color {
        let base: Color = isDarkModeEnabled ? .white : .black
        let opacity = (isDarkModeEnabled ? 0.10 : 0.14) * Double(contrastScale)
        return base.opacity(min(opacity, 0.6))
    }

    var borderWidth: CGFloat { max(0.5, 0.5 * contrastScale) }

    var selectedShadowOpacity: Double { min(0.4, 0.22 * Double(contrastScale)) }
    var selectedShadowRadius: CGFloat { 22 }

    // MARK: - Font scaling

    /// Scales a base point size by the current font scale.
    func size(_ base: CGFloat) -> CGFloat { base * fontScale }
}

// MARK: - Environment

private struct CardVisualsKey: EnvironmentKey {
    static let defaultValue = CardDetailVisualSettings()
}

extension EnvironmentValues {
    var cardVisuals: CardDetailVisualSettings {
        get { self[CardVisualsKey.self] }
        set { self[CardVisualsKey.self] = newValue }
    }
}
