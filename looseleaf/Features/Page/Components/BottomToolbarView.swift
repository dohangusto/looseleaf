import SwiftUI

/// Floating, translucent capsule toolbar with the four primary actions.
struct BottomToolbarView: View {
    var onAppearance: () -> Void = {}
    var onAttachment: () -> Void = {}
    var onSpecialInput: () -> Void = {}
    var onNewPage: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            // Main actions grouped in one capsule (anchored to the left).
            HStack(spacing: 28) {
                toolbarButton("slider.horizontal.3", action: onAppearance)
                toolbarButton("paperclip", action: onAttachment)
                toolbarButton("textformat", action: onSpecialInput)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)

            Spacer(minLength: 12)

            // New-page button anchored to the right.
            Button(action: onNewPage) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private func toolbarButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BottomToolbarView()
        .padding()
        .background(Color(.systemBackground))
}
