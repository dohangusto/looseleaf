import SwiftUI

struct StaggeredGridView: View {
    let entries: [JournalEntry]
    var heroNamespace: Namespace.ID? = nil
    var onPin: (JournalEntry) -> Void = { _ in }
    var onShare: (JournalEntry) -> Void = { _ in }
    var onDuplicate: (JournalEntry) -> Void = { _ in }
    var onDelete: (JournalEntry) -> Void = { _ in }

    private var leftColumn: [JournalEntry] {
        entries.enumerated().compactMap { index, entry in
            index % 2 == 0 ? entry : nil
        }
    }

    private var rightColumn: [JournalEntry] {
        entries.enumerated().compactMap { index, entry in
            index % 2 != 0 ? entry : nil
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 12) {
                ForEach(leftColumn) { entry in
                    card(for: entry)
                }
            }

            VStack(spacing: 12) {
                ForEach(rightColumn) { entry in
                    card(for: entry)
                }
            }
        }
    }

    private func card(for entry: JournalEntry) -> some View {
        NavigationLink(value: entry) {
            JournalCardView(entry: entry)
        }
        .buttonStyle(.plain)
        .zoomSourceIfPresent(id: entry.id, in: heroNamespace)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: entry))
        .accessibilityHint("Opens the note")
        .entryContextMenu(
            isPinned: entry.isPinned,
            onPin: { onPin(entry) },
            onShare: { onShare(entry) },
            onDuplicate: { onDuplicate(entry) },
            onDelete: { onDelete(entry) }
        )
    }

    private func accessibilityLabel(for entry: JournalEntry) -> String {
        var parts = [entry.title, entry.formattedDate]
        if let level = entry.level { parts.append(level.rawValue) }
        parts.append("\(entry.pageCount) pages")
        return parts.joined(separator: ", ")
    }
}
