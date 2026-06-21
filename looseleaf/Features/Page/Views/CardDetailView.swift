import SwiftUI

/// Detail screen for a selected card — an editable, paper-like note page.
/// For now every card opens this same screen with the same dummy data.
struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HomeViewModel.self) private var homeModel: HomeViewModel?

    let entry: JournalEntry

    init(entry: JournalEntry) {
        self.entry = entry
        // Each card already carries 2+ filled pages.
        _pages = State(initialValue: entry.pages.map {
            NotePage(title: $0.title, blocks: $0.blocks)
        })
    }

    // MARK: State
    @State private var pages: [NotePage]
    @State private var currentPageIndex = 0
    @State private var selectedBlockID: UUID?
    @State private var activeSheet: ActiveSheet?
    @State private var showSpecialMenu = false
    @State private var showAttachmentMenu = false
    @State private var voiceNoteSession: VoiceNoteSession?
    @State private var newRecordingCount = 1
    @State private var imageContextMenuBlockID: UUID?
    @State private var selectedType: InputBlockType = .default
    @State private var undoStack: [PageState] = []

    // Appearance / accessibility
    @State private var isAppearanceMenuPresented = false
    // Shared + persisted so the dark theme carries back to HomeView.
    @AppStorage("cardDarkModeEnabled") private var isDarkModeEnabled = false
    @State private var fontScale: CGFloat = 1.0
    @State private var contrastScale: CGFloat = 1.0

    // More actions
    @State private var showFindBar = false
    @State private var findQuery = ""
    @State private var matchIndex = 0
    @State private var visibleTypes: Set<InputBlockType> = Set(InputBlockType.selectableTypes)
    @State private var showTypeFilter = false
    @State private var layoutMode: PageLayoutMode = .standard
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    private var date: String { entry.detailDate }
    private var pageIndicator: String { "\(currentPageIndex + 1) of \(pages.count)" }

    private var canUndo: Bool { !undoStack.isEmpty }

    // MARK: - Current page proxies

    /// Editable title of the current page.
    private var pageTitle: Binding<String> { $pages[currentPageIndex].title }
    /// Editable blocks of the current page.
    private var blocksBinding: Binding<[InputBlock]> { $pages[currentPageIndex].blocks }
    /// Convenience read/write accessor used by the action helpers.
    private var blocks: [InputBlock] {
        get { pages[currentPageIndex].blocks }
        nonmutating set { pages[currentPageIndex].blocks = newValue }
    }
    private var currentTitle: String {
        get { pages[currentPageIndex].title }
        nonmutating set { pages[currentPageIndex].title = newValue }
    }
    private var isLocked: Bool {
        get { pages[currentPageIndex].isLocked }
        nonmutating set { pages[currentPageIndex].isLocked = newValue }
    }

    /// Editing is disabled while locked or in Read View.
    private var isEditable: Bool { !isLocked && layoutMode != .readView }

    private var canGoPreviousPage: Bool { currentPageIndex > 0 }
    private var canGoNextPage: Bool { currentPageIndex < pages.count - 1 }

    /// Blocks matching the current find query, in page order.
    private var matchIDs: [UUID] {
        guard showFindBar else { return [] }
        return blocks.filter { $0.matches(findQuery) }.map(\.id)
    }

    private var currentMatchID: UUID? {
        matchIDs.indices.contains(matchIndex) ? matchIDs[matchIndex] : nil
    }

    private var visuals: CardDetailVisualSettings {
        CardDetailVisualSettings(
            isDarkModeEnabled: isDarkModeEnabled,
            fontScale: fontScale,
            contrastScale: contrastScale
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            visuals.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBarView(
                    date: date,
                    pageIndicator: pageIndicator,
                    isUndoEnabled: canUndo,
                    canGoPrevious: canGoPreviousPage,
                    canGoNext: canGoNextPage,
                    onBack: { dismiss() },
                    onUndo: undo,
                    onPreviousPage: { goToPage(currentPageIndex - 1) },
                    onNextPage: { goToPage(currentPageIndex + 1) },
                    moreContent: { moreMenu }
                )

                if showFindBar {
                    FindInNoteBar(
                        query: $findQuery,
                        matchCount: matchIDs.count,
                        currentIndex: matchIndex,
                        onPrevious: { stepMatch(-1) },
                        onNext: { stepMatch(1) },
                        onClose: closeFind
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                EditablePageCanvasView(
                    title: pageTitle,
                    blocks: blocksBinding,
                    selectedBlockID: selectedBlockID,
                    imageContextMenuBlockID: $imageContextMenuBlockID,
                    isEditable: isEditable,
                    visibleTypes: visibleTypes,
                    currentMatchID: currentMatchID,
                    onBeginTextEdit: pushUndo,
                    onTapSpecialBlock: beginEditing,
                    onImageLongPress: { id in
                        imageContextMenuBlockID = id
                        selectedBlockID = id
                    },
                    onDeleteImage: deleteImage,
                    onCancelImageMenu: {
                        imageContextMenuBlockID = nil
                        selectedBlockID = nil
                    }
                )
                .id(pages[currentPageIndex].id)
                // Swipe horizontally to change pages (coexists with vertical scroll).
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            guard abs(dx) > abs(dy) * 1.5, abs(dx) > 60 else { return }
                            goToPage(currentPageIndex + (dx < 0 ? 1 : -1))
                        }
                )
                // VoiceOver three-finger swipe to change pages.
                .accessibilityScrollAction { edge in
                    switch edge {
                    case .leading: goToPage(currentPageIndex - 1)
                    case .trailing: goToPage(currentPageIndex + 1)
                    default: break
                    }
                }
            }

            // Tap-to-dismiss layer for the floating menus.
            if showSpecialMenu || showAttachmentMenu || isAppearanceMenuPresented {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { closeMenus() }
            }

            bottomArea
        }
        .environment(\.cardVisuals, visuals)
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        .animation(.easeInOut(duration: 0.2), value: isDarkModeEnabled)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet, onDismiss: { selectedBlockID = nil }) { sheet in
            editorSheet(for: sheet)
        }
        .fullScreenCover(item: $voiceNoteSession, onDismiss: { selectedBlockID = nil }) { session in
            voiceNoteScreen(for: session)
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL { ActivityView(items: [pdfURL]) }
        }
        .sheet(isPresented: $showTypeFilter) {
            ShowByTypeSheet(
                visibleTypes: $visibleTypes,
                onDone: { showTypeFilter = false },
                onMerge: mergeSelectedIntoOnePage
            )
        }
        .onChange(of: imageContextMenuBlockID) { _, newValue in
            if newValue == nil, activeSheet == nil { selectedBlockID = nil }
        }
        .onChange(of: findQuery) { _, _ in matchIndex = 0 }
        .onDisappear { persistBack() }
    }

    /// Writes the current pages back to the shared store when leaving the editor.
    private func persistBack() {
        let journalPages = pages.map { JournalPage(title: $0.title, blocks: $0.blocks) }
        homeModel?.updateEntry(id: entry.id, pages: journalPages)
    }

    // MARK: - More actions menu

    @ViewBuilder
    private var moreMenu: some View {
        // Scan + Lock share one row (side by side).
        ControlGroup {
            Button { scanToPDF() } label: { Label("Scan", systemImage: "doc.viewfinder") }
            Button { toggleLock() } label: {
                Label(isLocked ? "Unlock" : "Lock",
                      systemImage: isLocked ? "lock.open" : "lock")
            }
        }

        Button { openFind() } label: { Label("Find in Note", systemImage: "magnifyingglass") }

        Button { showTypeFilter = true } label: {
            Label("Show by Type", systemImage: "line.3.horizontal.decrease.circle")
        }

        Menu {
            Picker("Layout", selection: $layoutMode) {
                Label("Standard", systemImage: "doc.text").tag(PageLayoutMode.standard)
                Label("Landscape", systemImage: "rectangle.landscape.rotate").tag(PageLayoutMode.landscape)
                Label("Read View", systemImage: "book").tag(PageLayoutMode.readView)
            }
        } label: {
            Label("Layout Settings", systemImage: "square.split.2x1")
        }
    }


    // MARK: - More actions behavior

    private func scanToPDF() {
        pdfURL = PagePDFRenderer.makePDF(title: currentTitle, blocks: blocks)
        if pdfURL != nil { showShareSheet = true }
    }

    private func toggleLock() {
        closeMenus()
        if showFindBar { closeFind() }
        withAnimation { isLocked.toggle() }
    }

    private func openFind() {
        matchIndex = 0
        withAnimation { showFindBar = true }
    }

    private func closeFind() {
        findQuery = ""
        matchIndex = 0
        withAnimation { showFindBar = false }
    }

    private func stepMatch(_ direction: Int) {
        guard !matchIDs.isEmpty else { return }
        matchIndex = (matchIndex + direction + matchIDs.count) % matchIDs.count
    }

    // MARK: - Bottom area (toolbar + floating menu)

    @ViewBuilder
    private var bottomArea: some View {
        if isEditable {
            editingToolbarArea
        } else {
            statusBanner
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }

    /// Shown instead of the toolbar when the page is locked or in Read View.
    private var statusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: isLocked ? "lock.fill" : "book.fill")
            Text(isLocked
                 ? "Page locked — create a new page to keep writing."
                 : "Read View — editing is paused.")
                .font(.footnote)
                .fontWeight(.medium)
            Spacer(minLength: 8)
            if isLocked {
                Button("New Page") { addPage() }
                    .font(.footnote.weight(.semibold))
            } else {
                Button("Exit") { withAnimation { layoutMode = .standard } }
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    private var editingToolbarArea: some View {
        VStack(spacing: 12) {
            if isAppearanceMenuPresented {
                AppearanceMenuView(
                    isDarkModeEnabled: $isDarkModeEnabled,
                    fontScale: $fontScale,
                    contrastScale: $contrastScale,
                    onCancel: { closeMenus() }
                )
                .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
            }

            if showSpecialMenu {
                SpecialInputMenuView(selectedType: $selectedType) { type in
                    handleSpecialSelection(type)
                }
                .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
            }

            if showAttachmentMenu {
                AttachmentMenuView(
                    onTakePhoto: { insertImage() },
                    onChoosePhoto: { insertImage() },
                    onRecordAudio: { recordAudio() },
                    onCancel: { closeMenus() }
                )
                .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
            }

            BottomToolbarView(
                onAppearance: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSpecialMenu = false
                        showAttachmentMenu = false
                        isAppearanceMenuPresented.toggle()
                    }
                },
                onAttachment: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSpecialMenu = false
                        isAppearanceMenuPresented = false
                        showAttachmentMenu.toggle()
                    }
                },
                onSpecialInput: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAttachmentMenu = false
                        isAppearanceMenuPresented = false
                        showSpecialMenu.toggle()
                    }
                },
                onNewPage: { addPage() }
            )
        }
        .padding(.bottom, 8)
    }

    // MARK: - Attachment actions

    private func insertImage() {
        closeMenus()
        pushUndo()
        blocks.append(InputBlock(type: .image, imageName: "page-content_1"))
    }

    private func recordAudio() {
        closeMenus()
        voiceNoteSession = VoiceNoteSession(blockID: nil)
    }

    /// Builds the full-screen voice note view for either a new recording
    /// (create) or an existing block (edit/detail).
    @ViewBuilder
    private func voiceNoteScreen(for session: VoiceNoteSession) -> some View {
        if let id = session.blockID, let block = blocks.first(where: { $0.id == id }) {
            VoiceNoteInputView(
                mode: .edit,
                initialTitle: block.text,
                createdAt: block.createdAt,
                durationDetail: block.duration,
                transcript: block.transcript,
                onCancel: { voiceNoteSession = nil },
                onSave: { title in saveVoiceNote(session, title: title) }
            )
        } else {
            VoiceNoteInputView(
                mode: .create,
                initialTitle: "New Recording \(newRecordingCount)",
                createdAt: DateStamp.now(),
                durationDetail: "00:00",
                onCancel: { voiceNoteSession = nil },
                onSave: { title in saveVoiceNote(session, title: title) }
            )
        }
    }

    private func saveVoiceNote(_ session: VoiceNoteSession, title: String) {
        pushUndo()
        if let id = session.blockID, let index = blocks.firstIndex(where: { $0.id == id }) {
            // Edit mode — only the title is editable; transcript/date preserved.
            blocks[index].text = title
        } else {
            // New dummy recording with an AI-style transcript.
            blocks.append(
                InputBlock(type: .voiceNote,
                           text: title,
                           duration: "00:12",
                           transcript: "Ini transkrip otomatis dari rekaman tadi. Intinya aku cuma mau nyatet ide ini sebelum keburu lupa.",
                           createdAt: DateStamp.now())
            )
            newRecordingCount += 1
        }
        voiceNoteSession = nil
    }


    // MARK: - Special input selection (create flows)

    private func handleSpecialSelection(_ type: InputBlockType) {
        closeMenus()
        selectedType = type

        switch type {
        case .default:
            break // Return to normal plain-text writing mode.
        case .image:
            // Dummy insert of the provided asset.
            pushUndo()
            blocks.append(InputBlock(type: .image, imageName: "page-content_1"))
        case .text:
            pushUndo()
            blocks.append(InputBlock(type: .text, text: "Styled text"))
        case .vocabulary, .quote, .voiceNote, .expenses:
            // Open a creation sheet for these types.
            activeSheet = ActiveSheet(type: type, mode: .create)
        }
    }

    private func closeMenus() {
        withAnimation(.easeOut(duration: 0.15)) {
            showSpecialMenu = false
            showAttachmentMenu = false
            isAppearanceMenuPresented = false
        }
    }

    // MARK: - Editing existing special blocks

    private func beginEditing(_ block: InputBlock) {
        selectedBlockID = block.id
        if block.type == .voiceNote {
            // Voice notes open the dedicated full-screen editor.
            voiceNoteSession = VoiceNoteSession(blockID: block.id)
        } else {
            activeSheet = ActiveSheet(type: block.type, mode: .edit, blockID: block.id)
        }
    }

    // MARK: - Sheet builder

    @ViewBuilder
    private func editorSheet(for sheet: ActiveSheet) -> some View {
        let existing = sheet.blockID.flatMap { id in blocks.first(where: { $0.id == id }) }
        let titlePrefix = sheet.mode == .create ? "New" : "Edit"

        switch sheet.type {
        case .vocabulary:
            VocabularyEditorSheet(
                title: "\(titlePrefix) Vocabulary",
                word: existing?.text ?? "",
                meaning: existing?.secondaryText ?? "",
                onCancel: { activeSheet = nil },
                onSave: { word, meaning in
                    commit(sheet) { block in
                        block.text = word
                        block.secondaryText = meaning
                    } create: {
                        InputBlock(type: .vocabulary, text: word, secondaryText: meaning)
                    }
                }
            )
        case .quote:
            QuoteEditorSheet(
                title: "\(titlePrefix) Quote",
                quote: existing?.text ?? "",
                context: existing?.secondaryText ?? "",
                onCancel: { activeSheet = nil },
                onSave: { quote, context in
                    commit(sheet) { block in
                        block.text = quote
                        block.secondaryText = context
                    } create: {
                        InputBlock(type: .quote, text: quote, secondaryText: context)
                    }
                }
            )
        case .expenses:
            ExpensesTableEditorSheet(
                title: "\(titlePrefix) Expenses",
                rows: existing?.expenses ?? CardDetailView.sampleExpenses,
                onCancel: { activeSheet = nil },
                onSave: { rows in
                    commit(sheet) { block in
                        block.expenses = rows
                    } create: {
                        InputBlock(type: .expenses, expenses: rows)
                    }
                }
            )
        case .default, .image, .text, .voiceNote:
            EmptyView()
        }
    }

    /// Applies an edit or create, snapshotting state for undo first.
    private func commit(_ sheet: ActiveSheet,
                        edit: (inout InputBlock) -> Void,
                        create: () -> InputBlock) {
        pushUndo()
        switch sheet.mode {
        case .edit:
            if let id = sheet.blockID, let index = blocks.firstIndex(where: { $0.id == id }) {
                edit(&blocks[index])
            }
        case .create:
            blocks.append(create())
        }
        activeSheet = nil
    }

    // MARK: - Image deletion

    private func deleteImage(_ id: UUID) {
        pushUndo()
        blocks.removeAll { $0.id == id }
        imageContextMenuBlockID = nil
        selectedBlockID = nil
    }

    // MARK: - Undo

    private func pushUndo() {
        let snapshot = PageState(title: currentTitle, blocks: blocks)
        // Skip consecutive no-op snapshots (e.g. focusing without typing).
        if undoStack.last?.signature == snapshot.signature { return }
        undoStack.append(snapshot)
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        currentTitle = previous.title
        blocks = previous.blocks
        selectedBlockID = nil
    }

    // MARK: - Pages

    private func goToPage(_ index: Int) {
        guard pages.indices.contains(index) else { return }
        selectedBlockID = nil
        if showFindBar { closeFind() }
        withAnimation(.easeInOut(duration: 0.2)) { currentPageIndex = index }
    }

    /// Creates a new blank page and navigates to it. Undo history resets for
    /// the fresh page.
    private func addPage() {
        closeMenus()
        pages.append(NotePage(title: "", blocks: []))
        undoStack.removeAll()
        goToPage(pages.count - 1)
    }

    /// Gathers every block of the currently-selected types from all pages into
    /// one new page, then navigates to it.
    private func mergeSelectedIntoOnePage() {
        let selected = visibleTypes
        let merged = pages.flatMap { page in
            page.blocks.filter { selected.contains($0.type.filterCategory) }
        }
        showTypeFilter = false
        guard !merged.isEmpty else { return }

        let label = InputBlockType.selectableTypes
            .filter { selected.contains($0) }
            .map(\.label)
            .joined(separator: " + ")
        pages.append(NotePage(title: "Merged · \(label)", blocks: merged))
        visibleTypes = Set(InputBlockType.selectableTypes) // show everything on the merged page
        undoStack.removeAll()
        goToPage(pages.count - 1)
    }

    // MARK: - Dummy data

    static let sampleExpenses: [ExpenseRow] = [
        ExpenseRow(category: "mie ayam", amount: 18000),
        ExpenseRow(category: "transjakarta", amount: 3500),
        ExpenseRow(category: "gojek", amount: 26000),
        ExpenseRow(category: "kopi", amount: 17000),
    ]

}

// MARK: - Supporting types

/// A single editable page within a card. A card can hold several pages.
struct NotePage: Identifiable {
    let id = UUID()
    var title: String
    var blocks: [InputBlock]
    var isLocked: Bool = false
}

/// Page presentation modes from the Layout Settings submenu.
enum PageLayoutMode {
    case standard
    case landscape
    case readView
}

/// Identifies a full-screen voice note session (create when `blockID` is nil).
struct VoiceNoteSession: Identifiable {
    let id = UUID()
    var blockID: UUID?
}

/// Identifies which editor sheet is presented.
struct ActiveSheet: Identifiable {
    enum Mode { case create, edit }
    let id = UUID()
    let type: InputBlockType
    let mode: Mode
    var blockID: UUID? = nil
}

/// An immutable snapshot of the page used for undo.
struct PageState {
    var title: String
    var blocks: [InputBlock]

    /// Lightweight content signature for de-duplicating undo snapshots.
    var signature: String {
        title + "|" + blocks.map { b in
            "\(b.id)\(b.type.rawValue)\(b.text)\(b.secondaryText)\(b.imageName ?? "")\(b.duration)"
                + b.expenses.map { "\($0.id)\($0.category)\($0.amount)" }.joined()
        }.joined(separator: ";")
    }
}

#Preview {
    NavigationStack {
        CardDetailView(entry: .sample)
    }
}
