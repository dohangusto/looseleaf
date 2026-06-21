import SwiftUI

enum JournalLevel: String, CaseIterable, Identifiable, Codable {
    case easyGoing = "easy going"
    case cheerful = "cheerful"
    case reflective = "reflective"
    case energetic = "energetic"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .easyGoing: return .green
        case .cheerful: return .orange
        case .reflective: return .blue
        case .energetic: return .red
        }
    }

    var icon: String {
        switch self {
        case .easyGoing: return "figure.walk"
        case .cheerful: return "figure.wave"
        case .reflective: return "figure.mind.and.body"
        case .energetic: return "figure.run"
        }
    }
}

/// One filled page of a card (title + content blocks).
struct JournalPage: Identifiable, Codable {
    var id = UUID()
    var title: String
    var blocks: [InputBlock]
}

struct JournalEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    let date: Date
    let level: JournalLevel?
    let caption: String
    /// HomeView card background image (`nil` renders a text card).
    let imageName: String?
    /// Rich, filled pages shown in the detail (Page) screen — always 2+.
    var pages: [JournalPage]
    /// Whether this card is pinned (shown as the featured card).
    var isPinned: Bool = false

    /// Number of pages (drives the stacked-card visual on the Home grid).
    var pageCount: Int { pages.count }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var formattedDate: String {
        Self.formatted(date, "EEEE, d MMMM yyyy")
    }

    var shortFormattedDate: String {
        Self.formatted(date, "d MMMM yyyy")
    }

    /// Compact date used in the detail top bar, e.g. "Monday, 15 June".
    var detailDate: String {
        Self.formatted(date, "EEEE, d MMMM")
    }

    private static func formatted(_ date: Date, _ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    /// True if the query matches the title, caption, date, or any page content.
    func matchesSearch(_ query: String) -> Bool {
        if title.lowercased().contains(query) { return true }
        if caption.lowercased().contains(query) { return true }
        if formattedDate.lowercased().contains(query) { return true }
        return pages.contains { page in
            page.title.lowercased().contains(query)
                || page.blocks.contains { $0.searchableText.contains(query) }
        }
    }

    // Identity is the stable id — blocks are excluded from Hashable/Equatable
    // (InputBlock isn't Hashable, and id uniqueness is sufficient for routing).
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension JournalEntry {
    /// A single rich sample entry for previews.
    static let sample = JournalEntry(
        title: "Morning in Kyoto",
        date: Date(),
        level: .reflective,
        caption: "A crisp, slow morning with clearer thoughts than usual.",
        imageName: "page-content_1",
        pages: [
            JournalPage(title: "Morning in Kyoto", blocks: [
                InputBlock(type: .default, text: "Woke up early and let the morning be slow for once."),
                InputBlock(type: .image, imageName: "page-content_1"),
                InputBlock(type: .vocabulary, text: "Komorebi —",
                           secondaryText: "sunlight filtering through trees", language: "English"),
                InputBlock(type: .quote, text: "Mulai dari dirimu sendiri.",
                           secondaryText: "Tidak ada yang berubah kalau tidak ada yang bergerak"),
            ]),
            JournalPage(title: "Morning in Kyoto — Part 2", blocks: [
                InputBlock(type: .default, text: "Later I jotted down a few expenses from the cafe."),
                InputBlock(type: .expenses, expenses: [
                    ExpenseRow(category: "kopi", amount: 24000),
                    ExpenseRow(category: "roti", amount: 15000),
                ]),
            ]),
        ]
    )
}
