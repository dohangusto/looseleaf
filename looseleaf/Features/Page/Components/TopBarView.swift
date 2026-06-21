import SwiftUI

/// Light, floating top navigation: back + date/page on the left,
/// undo and a "more actions" menu on the right.
struct TopBarView<MoreContent: View>: View {
    let date: String
    let pageIndicator: String
    var isUndoEnabled: Bool = true
    var canGoPrevious: Bool = false
    var canGoNext: Bool = false
    var onBack: () -> Void = {}
    var onUndo: () -> Void = {}
    var onPreviousPage: () -> Void = {}
    var onNextPage: () -> Void = {}
    @ViewBuilder var moreContent: () -> MoreContent

    private var showPageNav: Bool { canGoPrevious || canGoNext }

    var body: some View {
        HStack(spacing: 12) {
            circleButton("chevron.left", action: onBack)

            VStack(alignment: .leading, spacing: 1) {
                Text(date)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    if showPageNav {
                        Button(action: onPreviousPage) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!canGoPrevious)
                        .accessibilityLabel("Previous page")
                    }

                    Text(pageIndicator)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Page, \(pageIndicator)")

                    if showPageNav {
                        Button(action: onNextPage) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(!canGoNext)
                        .accessibilityLabel("Next page")
                    }
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer()

            circleButton("arrow.uturn.backward", action: onUndo, enabled: isUndoEnabled)

            Menu {
                moreContent()
            } label: {
                circleIcon("ellipsis")
            }
            .tint(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func circleButton(_ systemName: String,
                              action: @escaping () -> Void,
                              enabled: Bool = true) -> some View {
        Button(action: action) {
            circleIcon(systemName, enabled: enabled)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }

    private func circleIcon(_ systemName: String, enabled: Bool = true) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(enabled ? .primary : .secondary)
            .frame(width: 38, height: 38)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
    }
}

#Preview {
    TopBarView(date: "Monday, 15 June", pageIndicator: "1 of 2") {
        Button("Scan") {}
        Button("Lock") {}
    }
}
