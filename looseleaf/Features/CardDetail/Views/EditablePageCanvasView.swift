import SwiftUI

/// The document canvas: a continuous, editable note page made of mixed blocks.
/// Tapping anywhere — beside text, between blocks, or on empty space — focuses
/// the editor and shows the keyboard. Special blocks can be tapped to edit and
/// images long-pressed for contextual options.
struct EditablePageCanvasView: View {
    @Binding var title: String
    @Binding var blocks: [InputBlock]

    var selectedBlockID: UUID?
    @Binding var imageContextMenuBlockID: UUID?

    /// Called when a text field (title or plain text) gains focus, so the host
    /// can snapshot state for undo before edits begin.
    var onBeginTextEdit: () -> Void = {}
    var onTapSpecialBlock: (InputBlock) -> Void = { _ in }
    var onImageLongPress: (UUID) -> Void = { _ in }
    var onDeleteImage: (UUID) -> Void = { _ in }
    var onCancelImageMenu: () -> Void = {}

    /// Identifies the currently focused editable field on the page.
    enum Field: Hashable {
        case title
        case block(UUID)
    }

    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Title — always the first row and the strongest element.
                TextField("Title", text: $title, axis: .vertical)
                    .font(.largeTitle.bold())
                    .textInputAutocapitalization(.sentences)
                    .focused($focusedField, equals: .title)

                ForEach($blocks) { $block in
                    blockView(for: $block)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Tap-to-continue region below the last block.
                Color.clear
                    .frame(minHeight: 160)
                    .contentShape(Rectangle())
                    .onTapGesture { focusTrailingWritingBlock() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 140)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { focusTrailingWritingBlock() }
        .onChange(of: focusedField) { _, newValue in
            if newValue != nil { onBeginTextEdit() }
        }
    }

    // MARK: - Block rendering

    @ViewBuilder
    private func blockView(for block: Binding<InputBlock>) -> some View {
        let value = block.wrappedValue
        switch value.type {
        case .default, .text:
            // Plain editable text that blends into the page.
            TextField("", text: block.text, axis: .vertical)
                .font(value.type == .text ? .body.weight(.medium) : .body)
                .focused($focusedField, equals: .block(value.id))

        case .vocabulary:
            VocabularyBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onTapGesture { onTapSpecialBlock(value) }

        case .quote:
            QuoteBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .contentShape(Rectangle())
                .onTapGesture { onTapSpecialBlock(value) }

        case .voiceNote:
            VoiceNoteBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onTapGesture { onTapSpecialBlock(value) }

        case .expenses:
            ExpensesTableBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onTapGesture { onTapSpecialBlock(value) }

        case .image:
            ImageBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onLongPressGesture { onImageLongPress(value.id) }
                .popover(isPresented: imageMenuBinding(for: value.id)) {
                    ImageContextMenuView(
                        onDelete: { onDeleteImage(value.id) },
                        onCancel: onCancelImageMenu
                    )
                }
        }
    }

    private func imageMenuBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { imageContextMenuBlockID == id },
            set: { isShown in if !isShown { imageContextMenuBlockID = nil } }
        )
    }

    // MARK: - Focus handling

    /// Focuses the last free-writing block so the user can keep typing. If the
    /// page has no trailing writable block, one is appended first.
    private func focusTrailingWritingBlock() {
        if let last = blocks.last, last.type == .default || last.type == .text {
            focusedField = .block(last.id)
            return
        }

        if blocks.isEmpty && title.isEmpty {
            focusedField = .title
            return
        }

        var newBlock = InputBlock(type: .default)
        newBlock.text = ""
        blocks.append(newBlock)
        focusedField = .block(newBlock.id)
    }
}

#Preview {
    EditablePageCanvasView(
        title: .constant("Car Patrol"),
        blocks: .constant([
            InputBlock(type: .default, text: "Put your hands up dawg!"),
            InputBlock(type: .vocabulary, text: "Komorebi —", secondaryText: "sunlight filtering through trees"),
        ]),
        selectedBlockID: nil,
        imageContextMenuBlockID: .constant(nil)
    )
}
