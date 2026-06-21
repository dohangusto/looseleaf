import SwiftUI

enum JournalLevel: String, CaseIterable, Identifiable {
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

struct JournalEntry: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: Date
    let level: JournalLevel?
    let caption: String
    let pageCount: Int
    /// HomeView card background image (`nil` renders a text card).
    let imageName: String?
    /// Rich page content shown in the detail (Page) screen.
    let blocks: [InputBlock]

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
        pageCount: 2,
        imageName: "page-content_1",
        blocks: [
            InputBlock(type: .default, text: "Woke up early and let the morning be slow for once."),
            InputBlock(type: .image, imageName: "page-content_1"),
            InputBlock(type: .vocabulary, text: "Komorebi —",
                       secondaryText: "sunlight filtering through trees"),
            InputBlock(type: .quote, text: "Mulai dari dirimu sendiri.",
                       secondaryText: "Tidak ada yang berubah kalau tidak ada yang bergerak"),
            InputBlock(type: .expenses, expenses: [
                ExpenseRow(category: "kopi", amount: 24000),
                ExpenseRow(category: "roti", amount: 15000),
            ]),
        ]
    )
}
