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
    let imageName: String?

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: date)
    }

    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
