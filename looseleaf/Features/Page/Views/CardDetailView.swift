import SwiftUI

/// Detail screen for a selected card — an editable, paper-like note page.
/// For now every card opens this same screen with the same dummy data.
struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry

    init(entry: JournalEntry) {
        self.entry = entry
        _pageTitle = State(initialValue: entry.title)
        _blocks = State(initialValue: entry.blocks)
    }

    // MARK: State
    @State private var pageTitle: String
    @State private var blocks: [InputBlock]
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

    private var date: String { entry.detailDate }
    private var pageIndicator: String { "1 of \(entry.pageCount)" }

    private var canUndo: Bool { !undoStack.isEmpty }

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
                    onBack: { dismiss() },
                    onUndo: undo,
                    onMore: {}
                )

                EditablePageCanvasView(
                    title: $pageTitle,
                    blocks: $blocks,
                    selectedBlockID: selectedBlockID,
                    imageContextMenuBlockID: $imageContextMenuBlockID,
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
        .onChange(of: imageContextMenuBlockID) { _, newValue in
            if newValue == nil, activeSheet == nil { selectedBlockID = nil }
        }
    }

    // MARK: - Bottom area (toolbar + floating menu)

    private var bottomArea: some View {
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
                onNewPage: {}
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
                createdAt: Self.nowString,
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
                           createdAt: Self.nowString)
            )
            newRecordingCount += 1
        }
        voiceNoteSession = nil
    }

    private static var nowString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: Date())
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
        let snapshot = PageState(title: pageTitle, blocks: blocks)
        // Skip consecutive no-op snapshots (e.g. focusing without typing).
        if undoStack.last?.signature == snapshot.signature { return }
        undoStack.append(snapshot)
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        pageTitle = previous.title
        blocks = previous.blocks
        selectedBlockID = nil
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
