import SwiftUI

/// Bottom sheet to create or edit a Vocabulary block.
struct VocabularyEditorSheet: View {
    let title: String
    @State private var word: String
    @State private var meaning: String
    var onCancel: () -> Void
    var onSave: (_ word: String, _ meaning: String) -> Void

    init(title: String,
         word: String,
         meaning: String,
         onCancel: @escaping () -> Void,
         onSave: @escaping (String, String) -> Void) {
        self.title = title
        self._word = State(initialValue: word)
        self._meaning = State(initialValue: meaning)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        labeledField("Word", text: $word, placeholder: "Komorebi —")
                        labeledField("Meaning", text: $meaning, placeholder: "sunlight filtering through trees")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        VocabularyBlockView(
                            block: InputBlock(type: .vocabulary, text: word, secondaryText: meaning)
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmButton { onSave(word, meaning) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text, axis: .vertical)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
        }
    }
}

#Preview {
    VocabularyEditorSheet(title: "Edit Vocabulary",
                          word: "Komorebi —",
                          meaning: "sunlight filtering through trees",
                          onCancel: {}, onSave: { _, _ in })
}
