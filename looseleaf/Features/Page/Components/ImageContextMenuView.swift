import SwiftUI

/// Lightweight floating options shown when an image block is long-pressed.
struct ImageContextMenuView: View {
    var onDelete: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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

            Button(action: onCancel) {
                Label("Cancel", systemImage: "xmark")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.primary)
        }
        .frame(width: 220)
        .buttonStyle(.plain)
        .background(.regularMaterial)
        .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    ImageContextMenuView(onDelete: {}, onCancel: {})
}
