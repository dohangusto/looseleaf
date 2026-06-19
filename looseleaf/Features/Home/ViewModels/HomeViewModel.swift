import SwiftUI

@Observable
class HomeViewModel {
    var entries: [JournalEntry] = []
    var selectedFilter: JournalLevel? = nil

    var filteredEntries: [JournalEntry] {
        guard let filter = selectedFilter else { return entries }
        return entries.filter { $0.level == filter }
    }

    var featuredEntry: JournalEntry? {
        filteredEntries.first
    }

    var gridEntries: [JournalEntry] {
        Array(filteredEntries.dropFirst())
    }

    var totalPages: Int {
        entries.reduce(0) { $0 + $1.pageCount }
    }

    init() {
        loadDummyData()
    }

    private func loadDummyData() {
        let calendar = Calendar.current
        let today = Date()

        entries = [
            JournalEntry(
                title: "Morning in Kyoto",
                date: today,
                level: nil,
                caption: "Woke up to a crisp autumn breeze today. The clarity of thought feels different this morning, more focused, more deliberate.",
                pageCount: 1,
                imageName: "Sunset View 1"
            ),
            JournalEntry(
                title: "Car Patrol",
                date: calendar.date(byAdding: .day, value: -4, to: today)!,
                level: .easyGoing,
                caption: "It is a long established fact that a reader will be distracted by the readable content of a page.",
                pageCount: 1,
                imageName: nil
            ),
            JournalEntry(
                title: "Lorem Ipsum Dolor Suit",
                date: calendar.date(byAdding: .day, value: -9, to: today)!,
                level: .cheerful,
                caption: "",
                pageCount: 3,
                imageName: "Sunset View 2"
            ),
            JournalEntry(
                title: "Lorem Ipsum Dolor Suit",
                date: calendar.date(byAdding: .day, value: -10, to: today)!,
                level: .easyGoing,
                caption: "It is a long established fact that a reader will be distracted by the readable content of a page.",
                pageCount: 1,
                imageName: nil
            ),
            JournalEntry(
                title: "Lorem Ipsum Dolor Suit",
                date: calendar.date(byAdding: .day, value: -11, to: today)!,
                level: .easyGoing,
                caption: "It is a long established fact that a reader will be distracted by the readable content of a page.",
                pageCount: 2,
                imageName: nil
            ),
            JournalEntry(
                title: "Lorem Ipsum Dolor Suit",
                date: calendar.date(byAdding: .day, value: -13, to: today)!,
                level: .reflective,
                caption: "",
                pageCount: 2,
                imageName: "Sunset View 3"
            ),
            JournalEntry(
                title: "Lorem Ipsum Dolor Suit",
                date: calendar.date(byAdding: .day, value: -15, to: today)!,
                level: .cheerful,
                caption: "It is a long established fact that a reader will be distracted by the readable content of a page.",
                pageCount: 1,
                imageName: nil
            ),
        ]
    }
}
