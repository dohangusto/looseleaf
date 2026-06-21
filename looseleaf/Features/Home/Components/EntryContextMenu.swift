import SwiftUI

/// Long-press context menu for a card: Pin, Share, Duplicate, Delete.
struct EntryContextMenu: ViewModifier {
    let isPinned: Bool
    var onPin: () -> Void
    var onShare: () -> Void
    var onDuplicate: () -> Void
    var onDelete: () -> Void

    func body(content: Content) -> some View {
        content.contextMenu {
            Button(action: onPin) {
                Label(isPinned ? "Unpin" : "Pin",
                      systemImage: isPinned ? "pin.slash" : "pin")
            }
            Button(action: onShare) {
                Label("Share as PDF", systemImage: "square.and.arrow.up")
            }
            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

extension View {
    func entryContextMenu(isPinned: Bool,
                          onPin: @escaping () -> Void,
                          onShare: @escaping () -> Void,
                          onDuplicate: @escaping () -> Void,
                          onDelete: @escaping () -> Void) -> some View {
        modifier(EntryContextMenu(isPinned: isPinned, onPin: onPin,
                                  onShare: onShare, onDuplicate: onDuplicate, onDelete: onDelete))
    }
}
