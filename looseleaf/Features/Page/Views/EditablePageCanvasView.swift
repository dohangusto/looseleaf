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

    /// When false (locked / read view) the page is non-editable.
    var isEditable: Bool = true
    /// Only blocks of these types are shown ("Show by Type").
    var visibleTypes: Set<InputBlockType> = Set(InputBlockType.allCases)
    /// The block currently highlighted/scrolled-to by "Find in Note".
    var currentMatchID: UUID? = nil

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
    @Environment(\.cardVisuals) private var visuals

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Title — always the first row and the strongest element.
                    TextField("Title", text: $title, axis: .vertical)
                        .font(.system(size: visuals.size(34), weight: .bold))
                        .foregroundStyle(visuals.primaryText)
                        .textInputAutocapitalization(.sentences)
                        .focused($focusedField, equals: .title)
                        .disabled(!isEditable)

                    ForEach($blocks) { $block in
                        row(for: $block)
                    }

                    // Tap-to-continue region below the last block.
                    Color.clear
                        .frame(minHeight: 160)
                        .contentShape(Rectangle())
                        .onTapGesture { if isEditable { focusTrailingWritingBlock() } }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture { if isEditable { focusTrailingWritingBlock() } }
            .onChange(of: focusedField) { _, newValue in
                if newValue != nil { onBeginTextEdit() }
            }
            .onChange(of: currentMatchID) { _, id in
                guard let id else { return }
                withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    // MARK: - Block rendering

    @ViewBuilder
    private func row(for block: Binding<InputBlock>) -> some View {
        let value = block.wrappedValue
        if visibleTypes.contains(value.type.filterCategory) {
            blockView(for: block)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(currentMatchID == value.id ? 6 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentMatchID == value.id ? Color.yellow.opacity(0.30) : Color.clear)
                )
                .id(value.id)
        }
    }

    @ViewBuilder
    private func blockView(for block: Binding<InputBlock>) -> some View {
        let value = block.wrappedValue
        switch value.type {
        case .default, .text:
            // Plain editable text that blends into the page.
            TextField("", text: block.text, axis: .vertical)
                .font(.system(size: visuals.size(17),
                              weight: value.type == .text ? .medium : .regular))
                .foregroundStyle(visuals.primaryText)
                .focused($focusedField, equals: .block(value.id))
                .disabled(!isEditable)

        case .vocabulary:
            VocabularyBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onTapGesture { if isEditable { onTapSpecialBlock(value) } }

        case .quote:
            QuoteBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .contentShape(Rectangle())
                .onTapGesture { if isEditable { onTapSpecialBlock(value) } }

        case .voiceNote:
            VoiceNoteBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onTapGesture { if isEditable { onTapSpecialBlock(value) } }

        case .expenses:
            ExpensesTableBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onTapGesture { if isEditable { onTapSpecialBlock(value) } }

        case .image:
            ImageBlockView(block: value)
                .selectedBlock(selectedBlockID == value.id)
                .onLongPressGesture { if isEditable { onImageLongPress(value.id) } }
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
