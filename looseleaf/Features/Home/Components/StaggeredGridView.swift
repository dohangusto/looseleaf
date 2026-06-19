import SwiftUI

struct StaggeredGridView: View {
    let entries: [JournalEntry]

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
                    NavigationLink(value: entry) {
                        JournalCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 12) {
                ForEach(rightColumn) { entry in
                    NavigationLink(value: entry) {
                        JournalCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
