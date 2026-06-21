import SwiftUI

enum SortOrder: String, CaseIterable, Identifiable {
    case newest, oldest, mood
    var id: String { rawValue }
    var label: String {
        switch self {
        case .newest: return "Newest first"
        case .oldest: return "Oldest first"
        case .mood: return "By mood"
        }
    }
}

/// A titled group of cards (e.g. "Today", "This Week", "Earlier").
struct EntrySection: Identifiable {
    let id: String
    let title: String
    let entries: [JournalEntry]
}

@Observable
class HomeViewModel {
    var entries: [JournalEntry] = []
    var selectedFilter: JournalLevel? = nil
    var searchQuery: String = ""
    var sortOrder: SortOrder = .newest

    private let store = NoteStore()

    var isSearchActive: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredEntries: [JournalEntry] {
        var result = entries
        if let filter = selectedFilter {
            result = result.filter { $0.level == filter }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.matchesSearch(query) }
        }
        return result
    }

    /// The pinned card is the "today" entry — shown only when it passes the
    /// active filter and no search is in progress.
    var featuredEntry: JournalEntry? {
        guard !isSearchActive else { return nil }
        guard let pinned = entries.first(where: { $0.isPinned }) else { return nil }
        if let filter = selectedFilter, pinned.level != filter { return nil }
        return pinned
    }

    var gridEntries: [JournalEntry] {
        filteredEntries.filter { $0.id != featuredEntry?.id }
    }

    /// Grid cards grouped into time buckets, each sorted by `sortOrder`.
    var gridSections: [EntrySection] {
        let calendar = Calendar.current
        let now = Date()
        var today: [JournalEntry] = []
        var week: [JournalEntry] = []
        var earlier: [JournalEntry] = []

        for entry in gridEntries {
            if calendar.isDateInToday(entry.date) {
                today.append(entry)
            } else if let days = calendar.dateComponents([.day], from: entry.date, to: now).day, days < 7 {
                week.append(entry)
            } else {
                earlier.append(entry)
            }
        }

        var sections: [EntrySection] = []
        if !today.isEmpty { sections.append(.init(id: "today", title: "Today", entries: sorted(today))) }
        if !week.isEmpty { sections.append(.init(id: "week", title: "This Week", entries: sorted(week))) }
        if !earlier.isEmpty { sections.append(.init(id: "earlier", title: "Earlier", entries: sorted(earlier))) }
        return sections
    }

    private func sorted(_ entries: [JournalEntry]) -> [JournalEntry] {
        switch sortOrder {
        case .newest: return entries.sorted { $0.date > $1.date }
        case .oldest: return entries.sorted { $0.date < $1.date }
        case .mood: return entries.sorted { ($0.level?.rawValue ?? "~") < ($1.level?.rawValue ?? "~") }
        }
    }

    var hasResults: Bool {
        featuredEntry != nil || !gridEntries.isEmpty
    }

    var totalPages: Int {
        entries.reduce(0) { $0 + $1.pageCount }
    }

    init() {
        entries = store.load()
    }

    private func persist() {
        store.save(entries)
    }

    /// Creates a new, empty entry dated today and inserts it at the top.
    @discardableResult
    func createEntry() -> JournalEntry {
        let entry = JournalEntry(
            title: "New Note",
            date: Date(),
            level: nil,
            caption: "",
            imageName: nil,
            pages: [JournalPage(title: "New Note", blocks: [])]
        )
        entries.insert(entry, at: 0)
        persist()
        return entry
    }

    // MARK: - Card actions

    func delete(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    /// Pins the given entry (and unpins any other), or unpins it if already pinned.
    func togglePin(_ entry: JournalEntry) {
        let willPin = !(entries.first { $0.id == entry.id }?.isPinned ?? false)
        for index in entries.indices {
            entries[index].isPinned = willPin && entries[index].id == entry.id
        }
        persist()
    }

    func duplicate(_ entry: JournalEntry) {
        let copy = JournalEntry(
            title: entry.title + " copy",
            date: Date(),
            level: entry.level,
            caption: entry.caption,
            imageName: entry.imageName,
            pages: entry.pages.map { JournalPage(title: $0.title, blocks: $0.blocks) },
            isPinned: false
        )
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries.insert(copy, at: index + 1)
        } else {
            entries.append(copy)
        }
        persist()
    }

    func resetSampleData() {
        selectedFilter = nil
        searchQuery = ""
        entries = store.reset()
    }

    /// Writes edited pages (and the representative title) back to the store.
    func updateEntry(id: UUID, pages: [JournalPage]) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].pages = pages
        if let firstTitle = pages.first?.title, !firstTitle.isEmpty {
            entries[index].title = firstTitle
        }
        persist()
    }
}

// MARK: - Dummy data generation

/// Builds 15 distinct, content-rich journal entries (one per day).
///
/// Every piece of textual content (text lines, vocabulary, quotes, voice notes,
/// expense tables) is handed out **without replacement** from shared pools, so
/// no data is ever duplicated within a card or across cards.
enum DummyJournal {
    static func makeEntries() -> [JournalEntry] {
        let calendar = Calendar.current
        let today = Date()
        var rng = SeededGenerator(seed: 0xC0FFEE15)
        var pool = ContentDispenser(rng: &rng)

        // Which grid positions (1..14) render as image-background cards.
        // Today (index 0) is always an image card (pinned thumbnail).
        var gridPositions = Array(1..<15)
        gridPositions.shuffle(using: &rng)
        let imagePositions = Set(gridPositions.prefix(7)) // 7 grid + today = 8 image cards

        let levels = JournalLevel.allCases

        return (0..<15).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let hasBackground = (i == 0) || imagePositions.contains(i)
            let backgroundImage = hasBackground
                ? "page-content_\(Int.random(in: 1...6, using: &rng))"
                : nil

            // Every card has 2–4 filled pages.
            let entryTitle = titles[i]
            let pageCount = Int.random(in: 2...4, using: &rng)
            let pages: [JournalPage] = (0..<pageCount).map { p in
                JournalPage(
                    title: p == 0 ? entryTitle : pool.nextPageTitle(rng: &rng),
                    blocks: pool.makeBlocks(rng: &rng, date: date)
                )
            }

            return JournalEntry(
                title: entryTitle,
                date: date,
                level: i == 0 ? .reflective : levels[i % levels.count],
                caption: captions[i],
                imageName: backgroundImage,
                pages: pages,
                isPinned: i == 0
            )
        }
    }

    // MARK: Content pools

    private static let titles = [
        "Morning in Kyoto", "Rainy Commute", "Coffee and Code", "Sunday Reset",
        "Late Night Thoughts", "Market Run", "Deep Work Day", "Long Walk Home",
        "Reading by the Window", "Budget Check-in", "Call with Mom", "First Sketch",
        "Gym and Greens", "Quiet Afternoon", "Planning the Week",
    ]

    private static let captions = [
        "A crisp, slow morning with clearer thoughts than usual.",
        "Soaked shoes, warm playlist, surprisingly good mood.",
        "Two cups in and the bug finally made sense.",
        "Laundry, dishes, and a long-overdue inbox cleanup.",
        "Couldn't sleep, so I wrote until my mind quieted down.",
        "Fresh greens, loud vendors, and a heavy tote bag.",
        "Phone on silent, four solid hours, no meetings.",
        "Took the long route just to keep thinking.",
        "Finished a chapter and stared at the rain for a while.",
        "Tallying the week and being honest about the coffee spend.",
        "She talked for an hour; I needed every minute of it.",
        "Rough lines, but the idea is finally on paper.",
        "Sore legs, big salad, small sense of victory.",
        "Nothing urgent, nothing loud — exactly what I needed.",
        "Mapping the next seven days before they map me.",
    ]

    // ~70 unique text lines.
    static let textPool: [String] = [
        "Woke up early and let the morning be slow for once.",
        "The rain didn't ask permission, so I just walked through it.",
        "Sat down with coffee and a stubborn function that refused to behave.",
        "Decided today is for resetting, not achieving.",
        "It's late and the apartment is quiet enough to hear myself think.",
        "The market was alive before I even had my coffee.",
        "Blocked the whole morning and actually protected it.",
        "I could've taken the bus, but my head needed the extra blocks.",
        "Curled up by the window with a book I keep restarting.",
        "Opened the notes app and finally faced the numbers.",
        "Mom called out of nowhere and it landed at the right time.",
        "Started sketching without a plan, which is the only way it works.",
        "Dragged myself to the gym and didn't regret it once.",
        "An afternoon with no agenda and no apologies for it.",
        "Sketching out the week so future-me has a fighting chance.",
        "You're not behind. You're just negotiating with discomfort.",
        "Dry socks fixed about eighty percent of my problems.",
        "Shipped it, closed the laptop, earned the silence.",
        "A reset isn't lost time. It's maintenance.",
        "Writing it down made it lighter than carrying it.",
        "Cooked what I bought. Small wins still count.",
        "Protecting focus is a skill, not a luxury.",
        "Some thoughts only untangle while you're moving.",
        "Left the chapter on a cliffhanger on purpose.",
        "Awareness first, guilt never. The spend is just data.",
        "Hung up smiling. That's the whole entry, honestly.",
        "Ugly first drafts are still drafts. Progress counts.",
        "Tired in the good way. Sleep will be easy tonight.",
        "Rest is also part of the work. I keep relearning that.",
        "A plan I can actually follow beats a perfect one I won't.",
        "The morning was quiet enough to hear my thoughts settle.",
        "I noticed I breathe differently when I'm not rushing.",
        "Wrote down the worry and it instantly felt smaller.",
        "Funny how a short walk reorganizes a messy head.",
        "I let one task be enough for the hour.",
        "The to-do list can wait until I've finished my coffee.",
        "Today I chose patience over pressure, and it helped.",
        "Some problems only dissolve once you stop staring at them.",
        "I caught myself comparing again and gently stopped.",
        "Slow progress is still the right direction.",
        "The desk was a mess but the work still got done.",
        "I protected two hours and the day felt twice as long.",
        "Rain on the window is an underrated soundtrack.",
        "I forgave the unfinished things and slept fine anyway.",
        "Small wins, counted honestly, add up faster than I think.",
        "I stopped negotiating with the snooze button today.",
        "A clear desk made for a clearer afternoon.",
        "I reminded myself that resting is also doing.",
        "The idea finally clicked while I was washing dishes.",
        "I said no to one thing so I could fully do another.",
        "Quiet mornings are where my best decisions hide.",
        "I let the draft be ugly and just kept moving.",
        "Today's plan fit on a sticky note, and that was perfect.",
        "I noticed the light change and just watched it for a while.",
        "Less scrolling, more reading — a fair trade tonight.",
        "I gave the hard task the first hour, not the last.",
        "Momentum is mostly about not stopping completely.",
        "I traded perfect for finished and felt lighter.",
        "The walk home took longer on purpose.",
        "I wrote three honest lines and kept only one.",
        "Tea, a window, and no notifications — small luxury.",
        "I let the silence do some of the thinking.",
        "Progress today looked a lot like just not quitting.",
        "I closed the laptop while I still had energy left.",
        "The market smelled like morning and possibility.",
        "I planned tomorrow so today could finally rest.",
        "One deep breath reset the whole afternoon.",
        "I chose the boring, reliable habit over the exciting one.",
        "Today I measured success by how calm I stayed.",
        "I let good enough actually be good enough.",
    ]

    // ~50 uncommon English vocabulary words (word, meaning, language).
    static let vocabPool: [(String, String, String)] = [
        ("collateral", "jaminan atau agunan", "English"),
        ("ephemeral", "sesuatu yang berlangsung sangat singkat", "English"),
        ("ubiquitous", "ada atau ditemukan di mana-mana", "English"),
        ("quintessential", "contoh paling sempurna dari suatu hal", "English"),
        ("serendipity", "penemuan baik yang terjadi secara kebetulan", "English"),
        ("idiosyncrasy", "kebiasaan unik khas seseorang", "English"),
        ("perfunctory", "dilakukan sekadarnya tanpa minat", "English"),
        ("sycophant", "penjilat yang mencari muka", "English"),
        ("equivocate", "berbicara ambigu untuk menghindari kebenaran", "English"),
        ("obfuscate", "membuat sesuatu jadi membingungkan dengan sengaja", "English"),
        ("pernicious", "berbahaya secara halus dan perlahan", "English"),
        ("magnanimous", "berjiwa besar dan murah hati", "English"),
        ("recalcitrant", "sulit diatur atau membangkang", "English"),
        ("sanguine", "optimistis di tengah situasi sulit", "English"),
        ("taciturn", "pendiam dan irit bicara", "English"),
        ("vociferous", "bersuara keras dan lantang", "English"),
        ("capricious", "mudah berubah-ubah tanpa alasan jelas", "English"),
        ("esoteric", "hanya dipahami kalangan tertentu", "English"),
        ("laconic", "menggunakan kata sesedikit mungkin", "English"),
        ("nascent", "baru mulai tumbuh atau berkembang", "English"),
        ("panacea", "obat atau solusi untuk segala masalah", "English"),
        ("quandary", "keadaan bingung memilih", "English"),
        ("surreptitious", "dilakukan diam-diam dan sembunyi", "English"),
        ("vicarious", "dirasakan lewat pengalaman orang lain", "English"),
        ("ameliorate", "memperbaiki atau meringankan keadaan", "English"),
        ("cacophony", "campuran suara yang sumbang dan bising", "English"),
        ("deleterious", "merugikan atau merusak", "English"),
        ("ennui", "rasa bosan dan hampa yang mendalam", "English"),
        ("fastidious", "sangat teliti dan sulit dipuaskan", "English"),
        ("garrulous", "banyak bicara soal hal sepele", "English"),
        ("hegemony", "dominasi satu kelompok atas yang lain", "English"),
        ("impetuous", "bertindak gegabah tanpa berpikir", "English"),
        ("mercurial", "suasana hati yang cepat berubah", "English"),
        ("nebulous", "kabur dan tidak jelas bentuknya", "English"),
        ("opulent", "mewah dan berlimpah", "English"),
        ("petulant", "mudah merajuk dan kesal", "English"),
        ("quagmire", "situasi sulit yang menjebak", "English"),
        ("sonorous", "bersuara dalam dan menggema", "English"),
        ("trepidation", "rasa cemas menjelang sesuatu", "English"),
        ("untenable", "tidak bisa dipertahankan", "English"),
        ("venerable", "dihormati karena usia atau kebijaksanaan", "English"),
        ("zenith", "titik tertinggi atau puncak", "English"),
        ("aplomb", "ketenangan dan rasa percaya diri", "English"),
        ("brusque", "ketus dan langsung ke inti", "English"),
        ("candor", "keterusterangan yang jujur", "English"),
        ("dearth", "kekurangan atau kelangkaan", "English"),
        ("gregarious", "suka bergaul dan ramai", "English"),
        ("harbinger", "pertanda akan datangnya sesuatu", "English"),
        ("insidious", "menyebar bahaya secara tersembunyi", "English"),
        ("truculent", "galak dan suka mencari ribut", "English"),
    ]

    // ~40 unique quotes.
    static let quotePool: [(String, String)] = [
        ("Mulai dari dirimu sendiri.", "Tidak ada yang berubah kalau tidak ada yang bergerak"),
        ("Sedikit demi sedikit, lama-lama menjadi bukit.", "Konsistensi mengalahkan intensitas"),
        ("Istirahat itu bagian dari progres.", "Bukan kemunduran, tapi pemulihan"),
        ("Pelan-pelan asal selamat.", "Tidak semua hal harus cepat"),
        ("Hari ini cukup, besok kita coba lagi.", "Self-compassion over perfection"),
        ("Kerjakan yang bisa dikerjakan hari ini.", "The rest can wait"),
        ("Tenang itu juga produktif.", "Calm is a kind of progress"),
        ("Jangan bandingkan bab satumu dengan bab dua puluh orang lain.", "Your pace is valid"),
        ("Bernapas dulu, baru bergerak.", "Breathe, then begin"),
        ("Kesalahan itu data, bukan vonis.", "Mistakes are data, not a verdict"),
        ("Showing up is half the battle.", "Konsistensi kecil itu nyata"),
        ("Rumah bukan tempat, tapi rasa.", "Home is a feeling"),
        ("Cukup itu juga sebuah pencapaian.", "Enough is an achievement too"),
        ("Lakukan dengan hati.", "Do it with soul — meraki"),
        ("Satu langkah hari ini.", "One step today beats none"),
        ("Tidur yang cukup itu strategi, bukan kemalasan.", "Recovery is a plan, not a pause"),
        ("Yang penting jalan, bukan harus lari.", "Direction over speed"),
        ("Fokus pada satu hal sampai selesai.", "One thing fully beats five things halfway"),
        ("Hari buruk bukan berarti hidup buruk.", "A bad day is just a day"),
        ("Mulai kecil, tapi mulai sekarang.", "Start small, start now"),
        ("Energi itu terbatas, pakai dengan sadar.", "Spend energy on purpose"),
        ("Kamu boleh lelah, tapi jangan menyerah.", "Tired is allowed, quitting isn't"),
        ("Perbandingan adalah pencuri kebahagiaan.", "Comparison is the thief of joy"),
        ("Hal kecil yang konsisten jadi besar.", "Small things, stacked, become big"),
        ("Diam sejenak bukan berarti berhenti.", "A pause is not a stop"),
        ("Selesai lebih baik daripada sempurna.", "Done beats perfect"),
        ("Beri ruang untuk dirimu bernapas.", "Make room to breathe"),
        ("Setiap orang punya garis waktunya sendiri.", "Your timeline is your own"),
        ("Kemarin pelajaran, hari ini kesempatan.", "Yesterday taught, today offers"),
        ("Berani memulai sudah setengah jalan.", "To begin is half the work"),
        ("Jangan menunggu siap, mulai saja.", "Readiness is built by starting"),
        ("Pikiran tenang membuat keputusan jernih.", "Calm minds choose clearly"),
        ("Rawat dirimu seperti merawat sahabat.", "Be your own friend"),
        ("Progres tak selalu terlihat tiap hari.", "Growth is often invisible up close"),
        ("Lebih baik lambat dan benar.", "Slow and right beats fast and wrong"),
        ("Cukup tahu arah, langkah akan menyusul.", "Know the direction, steps follow"),
        ("Istirahat dulu, dunia bisa menunggu.", "Rest first, the world can wait"),
        ("Kebiasaan kecil membentuk masa depan.", "Small habits shape the future"),
        ("Hargai usaha, bukan cuma hasil.", "Honor the effort, not just the outcome"),
        ("Satu hal baik hari ini sudah cukup.", "One good thing today is enough"),
    ]

    // ~30 unique voice notes (descriptive title, AI-transcribed transcript).
    static let voicePool: [(String, String)] = [
        ("Design feedback dari Kak Keke", "Jadi gini, menurut aku komponen kartunya itu mending pakai auto layout dulu ya, biar pas di-resize nggak berantakan. Terus spacing-nya tolong dikonsistenin, sekarang masih agak loncat-loncat."),
        ("Bacotan nongkrong di lobby", "Eh tadi si Dimas cerita katanya dia mau resign, terus pindah ke startup yang baru itu lho. Lumayan kaget sih, tapi ya semoga lancar aja lah ya."),
        ("Motivasiku hari ini", "Oke, pesan buat diri sendiri: hari ini nggak usah muluk-muluk, yang penting satu hal kelar dengan beres. Pelan-pelan aja, yang penting jalan terus."),
        ("Rangkuman meeting pagi", "Intinya dari meeting tadi, prioritas utama kita geser ke fitur pencarian dulu. Deadline-nya akhir bulan, jadi mulai besok kita fokus ke situ ya."),
        ("Ide random pas di kereta", "Kepikiran nih, gimana kalau halaman onboarding-nya dibikin tiga langkah aja, jangan kebanyakan. Biar orang nggak males di awal."),
        ("Curhat singkat sebelum tidur", "Hari ini lumayan berat sih, capek banget rasanya. Tapi ya udahlah, besok kita coba lagi. Yang penting sekarang istirahat dulu."),
        ("Catatan belanja mingguan", "Jangan lupa beli kopi, telur, sama roti gandum pas pulang nanti. Oh iya, sabun cuci piring juga udah mau habis."),
        ("Update progres proyek login", "Modul login-nya udah kelar ya, tinggal nyambungin ke API. Mungkin besok pagi udah bisa mulai testing-nya."),
        ("Brainstorm nama produk", "Aku lagi mikirin nama produk yang pendek dan gampang diinget. Mungkin satu kata aja, yang ada kesan hangat gitu."),
        ("Reminder bayar invoice", "Reminder penting nih, jangan sampai lupa kirim invoice ke klien sebelum jam lima sore hari ini."),
        ("Refleksi setelah olahraga", "Abis lari tiga kilo dan ternyata enak juga ya. Besok coba tambah jadi empat deh, pelan-pelan tapi konsisten."),
        ("Resume telepon sama klien", "Tadi telepon sama klien, mereka minta revisi kecil di bagian header. Selain itu mereka oke sama keseluruhan desainnya."),
        ("Rencana liburan akhir bulan", "Rencananya kita berangkat pagi-pagi ya biar nggak kena macet di tol. Nanti aku cek tiket keretanya malam ini."),
        ("Mood check sore ini", "Sore ini lumayan tenang sih, nggak terlalu banyak overthinking. Lumayan, jarang-jarang kepala seenteng ini."),
        ("Debugging out loud", "Oke jadi bug-nya ternyata ada di bagian state yang nggak ke-reset pas pindah halaman. Pantesan datanya nyangkut terus."),
        ("Standup harian tim", "Update harian ya: kemarin aku selesaikan bagian form, hari ini lanjut ke validasi sama testing-nya."),
        ("Sketsa ide layout baru", "Aku kepikiran bikin layout yang lebih lega, kurangi elemen yang nggak perlu. Biar fokus matanya ke konten utama aja."),
        ("Evaluasi pengeluaran kopi", "Jujur minggu ini agak boros di bagian jajan kopi. Mulai minggu depan coba dikurangin deh, seminggu dua kali aja."),
        ("Pesan buat diri sendiri", "Note to self: malam ini kurangi scroll-scroll, mending tambah waktu baca buku yang kemarin belum kelar itu."),
        ("Highlight bacaan hari ini", "Bab yang tadi aku baca ngomongin soal kebiasaan kecil yang lama-lama bikin perubahan besar. Relate banget sih."),
        ("Obrolan random sama Dimas", "Tadi ngobrol sama Dimas soal main fotografi lagi. Katanya weekend ini dia mau hunting, mungkin aku ikut."),
        ("Ngevoice pas macet di tol", "Lagi kejebak macet nih, jadi sekalian rekam aja. Inget, besok mulai dari tugas yang paling susah dulu biar entengan."),
        ("Catatan kelas pagi", "Dari kelas tadi, poin pentingnya itu jangan terlalu cepat optimasi. Bikin yang jalan dulu, baru dirapikan."),
        ("Insight dari podcast tadi", "Tadi dengerin podcast, ada satu kalimat yang nyantol: showing up itu udah setengah dari perjuangan. Bener juga ya."),
        ("Rencana minggu depan", "Minggu depan aku mau atur ulang jadwal. Pagi buat kerja fokus, sore buat olahraga, malam buat baca."),
        ("Keluh kesah deadline", "Deadline-nya kerasa mepet banget sih. Tapi ya udah, dikerjain satu-satu aja, nggak usah panik duluan."),
        ("Semangat pagi versi sendiri", "Selamat pagi, diri sendiri. Hari ini kita coba lebih sabar sama prosesnya ya. Hasil itu nyusul belakangan."),
        ("Notulen rapat mendadak", "Hasil rapat dadakan tadi: deadline mundur seminggu, jadi ada ruang lebih buat polish bagian detailnya."),
        ("Bisikan ide tengah malam", "Lagi nggak bisa tidur dan tiba-tiba kepikiran ide fitur. Rekam dulu deh sebelum lupa pas bangun besok."),
        ("Random thought di kamar mandi", "Suara hujan tadi bikin fokus ya. Mungkin pas kerja aku coba pakai white noise hujan gitu deh."),
    ]

    // ~18 unique expense tables.
    static let expensePool: [[(String, Int)]] = [
        [("kopi susu", 24000), ("roti", 15000), ("transjakarta", 3500)],
        [("nasi goreng", 22000), ("es teh", 6000), ("parkir", 4000), ("gojek", 19000)],
        [("mie ayam", 18000), ("transjakarta", 3500), ("gojek", 26000), ("kopi", 17000)],
        [("buku", 95000), ("pulpen", 12000), ("kopi", 18000)],
        [("sayur", 35000), ("ayam", 40000), ("buah", 28000), ("gojek", 15000)],
        [("tiket bioskop", 50000), ("popcorn", 30000), ("parkir", 10000)],
        [("bensin", 50000), ("tol", 16000), ("kopi", 20000)],
        [("makan siang", 27000), ("air mineral", 4000), ("gojek", 13000)],
        [("laundry", 30000), ("galon", 20000), ("token listrik", 50000)],
        [("pulsa", 25000), ("paket data", 60000), ("kopi", 17000)],
        [("sate", 35000), ("es jeruk", 8000), ("parkir", 3000)],
        [("buku tulis", 18000), ("spidol", 22000), ("map", 5000)],
        [("gym day pass", 40000), ("protein bar", 18000), ("air", 5000)],
        [("nasi padang", 28000), ("teh botol", 5000), ("gojek", 17000)],
        [("tiket kereta", 45000), ("snack", 15000), ("kopi", 19000)],
        [("bakso", 20000), ("es campur", 12000), ("transjakarta", 3500)],
        [("sabun", 18000), ("pasta gigi", 15000), ("shampoo", 27000)],
        [("donat", 28000), ("kopi", 24000), ("parkir", 4000)],
    ]

    static let imagePool: [String] = (1...6).map { "page-content_\($0)" }

    /// Distinct titles for pages after the first (the first keeps the card title).
    static let pageTitlePool: [String] = [
        "Things I noticed", "A small list", "Notes to future me", "Half-formed ideas",
        "Before I forget", "Quiet observations", "What stuck with me", "Loose threads",
        "Scratch pad", "Between the lines", "Afterthoughts", "Today's leftovers",
        "Random tangents", "On second thought", "The long version", "Footnotes",
        "Side quests", "Later, maybe", "Bits and pieces", "A clearer head",
        "The rundown", "Postscript", "Stray thoughts", "Second wind",
        "Odds and ends", "More of this", "The quiet part", "Unsorted",
        "Threads to pull", "Where my head went",
    ]
}

// MARK: - Content dispenser

/// Hands out content from shuffled pools. Items are unique until a pool is
/// exhausted, then it reshuffles and refills — so the many filled pages never
/// run out of content while keeping duplication spread far apart.
private struct ContentDispenser {
    private var texts: Refillable<String>
    private var vocab: Refillable<(String, String, String)>
    private var quotes: Refillable<(String, String)>
    private var voices: Refillable<(String, String)>
    private var expenses: Refillable<[(String, Int)]>
    private var images: Refillable<String>
    private var pageTitles: Refillable<String>

    init(rng: inout SeededGenerator) {
        texts = Refillable(DummyJournal.textPool, rng: &rng)
        vocab = Refillable(DummyJournal.vocabPool, rng: &rng)
        quotes = Refillable(DummyJournal.quotePool, rng: &rng)
        voices = Refillable(DummyJournal.voicePool, rng: &rng)
        expenses = Refillable(DummyJournal.expensePool, rng: &rng)
        images = Refillable(DummyJournal.imagePool, rng: &rng)
        pageTitles = Refillable(DummyJournal.pageTitlePool, rng: &rng)
    }

    /// A distinct title for a non-first page.
    mutating func nextPageTitle(rng: inout SeededGenerator) -> String {
        pageTitles.take(1, rng: &rng).first ?? "Untitled"
    }

    /// Builds one rich page with randomized quantities and a fully shuffled
    /// order. The page title is rendered separately, so it always stays first.
    mutating func makeBlocks(rng: inout SeededGenerator, date: Date) -> [InputBlock] {
        var blocks: [InputBlock] = []

        // At least 3 text lines guarantees every page is filled.
        for text in texts.take(Int.random(in: 3...6, using: &rng), rng: &rng) {
            blocks.append(InputBlock(type: .default, text: text))
        }
        for v in vocab.take(Int.random(in: 2...4, using: &rng), rng: &rng) {
            blocks.append(InputBlock(type: .vocabulary, text: "\(v.0) —",
                                     secondaryText: v.1, language: v.2))
        }
        for q in quotes.take(Int.random(in: 1...3, using: &rng), rng: &rng) {
            blocks.append(InputBlock(type: .quote, text: q.0, secondaryText: q.1))
        }
        for v in voices.take(Int.random(in: 0...2, using: &rng), rng: &rng) {
            let hour = Int.random(in: 7...22, using: &rng)
            let minute = Int.random(in: 0...59, using: &rng)
            blocks.append(InputBlock(
                type: .voiceNote,
                text: v.0,
                duration: String(format: "00:%02d", Int.random(in: 5...59, using: &rng)),
                transcript: v.1,
                createdAt: DateStamp.string(date: date, hour: hour, minute: minute)
            ))
        }
        for table in expenses.take(Int.random(in: 0...1, using: &rng), rng: &rng) {
            blocks.append(InputBlock(type: .expenses,
                                     expenses: table.map { ExpenseRow(category: $0.0, amount: $0.1) }))
        }
        for image in images.take(Int.random(in: 0...1, using: &rng), rng: &rng) {
            blocks.append(InputBlock(type: .image, imageName: image))
        }

        blocks.shuffle(using: &rng)
        return blocks
    }
}

/// A shuffled queue that refills (reshuffles the full source) when emptied.
private struct Refillable<Element> {
    private let source: [Element]
    private var queue: [Element]

    init(_ source: [Element], rng: inout SeededGenerator) {
        self.source = source
        self.queue = source.shuffled(using: &rng)
    }

    mutating func take(_ n: Int, rng: inout SeededGenerator) -> [Element] {
        guard !source.isEmpty else { return [] }
        var out: [Element] = []
        for _ in 0..<max(n, 0) {
            if queue.isEmpty { queue = source.shuffled(using: &rng) }
            out.append(queue.removeFirst())
        }
        return out
    }
}

// MARK: - Seeded RNG

/// A tiny deterministic generator so the layout looks random but stays stable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed != 0 ? seed : 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
