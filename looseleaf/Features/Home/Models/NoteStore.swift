import Foundation

/// Lightweight JSON-file persistence for the notes. Seeds the dummy data on
/// first launch, then reads/writes the user's actual notes.
struct NoteStore {
    private let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("notes.json")
    }()

    func load() -> [JournalEntry] {
        if let data = try? Data(contentsOf: url),
           let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            return entries
        }
        // First launch — seed with dummy content and persist it.
        let seed = DummyJournal.makeEntries()
        save(seed)
        return seed
    }

    func save(_ entries: [JournalEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Deletes the stored file and returns a freshly seeded set of entries.
    func reset() -> [JournalEntry] {
        try? FileManager.default.removeItem(at: url)
        let seed = DummyJournal.makeEntries()
        save(seed)
        return seed
    }
}
