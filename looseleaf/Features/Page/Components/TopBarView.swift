import SwiftUI

/// Light, floating top navigation: back + date/page on the left,
/// undo and more actions on the right.
struct TopBarView: View {
    let date: String
    let pageIndicator: String
    var isUndoEnabled: Bool = true
    var onBack: () -> Void = {}
    var onUndo: () -> Void = {}
    var onMore: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            circleButton("chevron.left", action: onBack)

            VStack(alignment: .leading, spacing: 1) {
                Text(date)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(pageIndicator)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            circleButton("arrow.uturn.backward", action: onUndo, enabled: isUndoEnabled)
            circleButton("ellipsis", action: onMore)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func circleButton(_ systemName: String,
                              action: @escaping () -> Void,
                              enabled: Bool = true) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? .primary : .secondary)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

#Preview {
    TopBarView(date: "Monday, 15 June", pageIndicator: "1 of 2")
}
