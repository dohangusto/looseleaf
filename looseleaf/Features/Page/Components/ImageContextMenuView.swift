import SwiftUI

/// Lightweight floating options shown when an image block is long-pressed.
struct ImageContextMenuView: View {
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}
    var onDelete: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row("Move Up", systemImage: "arrow.up", action: onMoveUp)
            Divider()
            row("Move Down", systemImage: "arrow.down", action: onMoveDown)
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete Image", systemImage: "trash")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.red)

            Divider()

            row("Cancel", systemImage: "xmark", action: onCancel)
        }
        .frame(width: 220)
        .buttonStyle(.plain)
        .background(.regularMaterial)
        .presentationCompactAdaptation(.popover)
    }

    private func row(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    ImageContextMenuView(onDelete: {}, onCancel: {})
}
