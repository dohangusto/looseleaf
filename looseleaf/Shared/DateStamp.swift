import Foundation

/// Shared date formatting for voice-note timestamps so generated dummy data
/// and freshly recorded notes use the same "d MMM yyyy, HH:mm" format.
enum DateStamp {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()

    static func now() -> String {
        formatter.string(from: Date())
    }

    static func string(date: Date, hour: Int, minute: Int) -> String {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        let stamped = Calendar.current.date(from: components) ?? date
        return formatter.string(from: stamped)
    }
}
