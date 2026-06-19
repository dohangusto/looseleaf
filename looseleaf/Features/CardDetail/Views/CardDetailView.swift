import SwiftUI

/// Detail screen for a selected card — an editable, paper-like note page.
/// For now every card opens this same screen with the same dummy data.
struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: State
    @State private var pageTitle: String = "Car Patrol"
    @State private var blocks: [InputBlock] = CardDetailView.sampleBlocks
    @State private var selectedBlockID: UUID?
    @State private var activeSheet: ActiveSheet?
    @State private var showSpecialMenu = false
    @State private var showAttachmentMenu = false
    @State private var voiceNoteSession: VoiceNoteSession?
    @State private var imageContextMenuBlockID: UUID?
    @State private var selectedType: InputBlockType = .default
    @State private var undoStack: [PageState] = []

    private let date = "Monday, 15 June"
    private let pageIndicator = "1 of 2"

    private var canUndo: Bool { !undoStack.isEmpty }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground)
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
            if showSpecialMenu || showAttachmentMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { closeMenus() }
            }

            bottomArea
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet, onDismiss: { selectedBlockID = nil }) { sheet in
            editorSheet(for: sheet)
        }
        .fullScreenCover(item: $voiceNoteSession, onDismiss: { selectedBlockID = nil }) { session in
            VoiceNoteInputView(
                onCancel: { voiceNoteSession = nil },
                onSave: { saveVoiceNote(session) }
            )
        }
        .onChange(of: imageContextMenuBlockID) { _, newValue in
            if newValue == nil, activeSheet == nil { selectedBlockID = nil }
        }
    }

    // MARK: - Bottom area (toolbar + floating menu)

    private var bottomArea: some View {
        VStack(spacing: 12) {
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
                onAppearance: {},
                onAttachment: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSpecialMenu = false
                        showAttachmentMenu.toggle()
                    }
                },
                onSpecialInput: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAttachmentMenu = false
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
        blocks.append(InputBlock(type: .image, imageName: "View 1"))
    }

    private func recordAudio() {
        closeMenus()
        voiceNoteSession = VoiceNoteSession(blockID: nil)
    }

    private func saveVoiceNote(_ session: VoiceNoteSession) {
        pushUndo()
        if let id = session.blockID, let index = blocks.firstIndex(where: { $0.id == id }) {
            // Edit mode — dummy screen has no editable fields, so content is
            // preserved; the snapshot above still makes the action undoable.
            blocks[index].createdAt = "Today, 09:41"
        } else {
            blocks.append(
                InputBlock(type: .voiceNote,
                           text: "Design Feedback",
                           duration: "00:01",
                           transcript: "Oke, kayaknya better kamu ubah komponen ini pake autolayout dulu...",
                           createdAt: "Today, 09:41")
            )
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
            blocks.append(InputBlock(type: .image, imageName: "View 1"))
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

    static let sampleBlocks: [InputBlock] = [
        InputBlock(type: .default, text: "Put your hands up dawg!"),
        InputBlock(type: .vocabulary, text: "Komorebi —",
                   secondaryText: "sunlight filtering through trees"),
        InputBlock(type: .image, imageName: "View 1"),
        InputBlock(type: .quote, text: "Mulai dari dirimu sendiri.",
                   secondaryText: "Tidak ada yang berubah kalau tidak ada yang bergerak"),
        InputBlock(type: .default,
                   text: "You’re not behind. You’re just in that part where your brain is trying to negotiate with discomfort. No negotiation today."),
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
        CardDetailView()
    }
}
