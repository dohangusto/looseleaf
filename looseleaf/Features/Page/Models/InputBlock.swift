import SwiftUI

/// The kinds of content a page can contain. `default` is normal free-writing;
/// the rest are special, visually distinct blocks.
enum InputBlockType: String, CaseIterable, Identifiable {
    case `default`
    case vocabulary
    case quote
    case voiceNote
    case image
    case text
    case expenses

    var id: String { rawValue }

    /// Special blocks (everything except free-writing) get distinct presentation,
    /// selection depth, and editing sheets.
    var isSpecial: Bool { self != .default }

    /// Types the user can filter by in "Show by Type". Plain free-writing
    /// (`.default`) is not listed separately — it belongs to the `.text` category.
    static var selectableTypes: [InputBlockType] {
        [.text, .vocabulary, .quote, .voiceNote, .image, .expenses]
    }

    /// The filter category a block belongs to (`.default` counts as `.text`).
    var filterCategory: InputBlockType {
        self == .default ? .text : self
    }

    var label: String {
        switch self {
        case .default: return "Default"
        case .vocabulary: return "Vocabulary"
        case .quote: return "Quotes"
        case .voiceNote: return "Voice Note"
        case .image: return "Image"
        case .text: return "Text"
        case .expenses: return "Expenses Tab"
        }
    }

    var icon: String {
        switch self {
        case .default: return "text.alignleft"
        case .vocabulary: return "character.book.closed"
        case .quote: return "quote.opening"
        case .voiceNote: return "waveform"
        case .image: return "photo"
        case .text: return "textformat"
        case .expenses: return "tablecells"
        }
    }
}

/// A single expense row inside an `.expenses` block.
struct ExpenseRow: Identifiable, Hashable {
    let id = UUID()
    var category: String
    var amount: Int
}

/// A content block on the page. Fields are reused across types; only the
/// relevant ones are populated for a given `type`.
struct InputBlock: Identifiable {
    let id = UUID()
    var type: InputBlockType

    /// Primary editable text (free text, vocabulary word, quote, voice-note title…).
    var text: String = ""
    /// Secondary supporting text (vocabulary meaning, quote author/description…).
    var secondaryText: String = ""
    /// Origin language of a vocabulary word, e.g. "English".
    var language: String = ""

    var imageName: String? = nil
    var duration: String = ""
    var expenses: [ExpenseRow] = []

    // Voice-note metadata.
    var transcript: String = ""
    var createdAt: String = ""

    var expensesTotal: Int {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// All searchable text in this block, lowercased — used by "Find in Note".
    var searchableText: String {
        var parts = [text, secondaryText, transcript, language]
        parts += expenses.map { "\($0.category) \($0.amount)" }
        return parts.joined(separator: " ").lowercased()
    }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return false }
        return searchableText.contains(q)
    }
}

/// Indonesian-style amount formatting: `18000` → `18.000`.
enum RupiahFormatter {
    static func string(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
