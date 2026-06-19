import SwiftUI

/// Lightweight placeholder sheet to create or edit a Voice Note block.
/// No real recording — just title + duration metadata for now.
struct VoiceNoteEditorSheet: View {
    let title: String
    @State private var noteTitle: String
    @State private var duration: String
    var onCancel: () -> Void
    var onSave: (_ title: String, _ duration: String) -> Void

    init(title: String,
         noteTitle: String,
         duration: String,
         onCancel: @escaping () -> Void,
         onSave: @escaping (String, String) -> Void) {
        self.title = title
        self._noteTitle = State(initialValue: noteTitle)
        self._duration = State(initialValue: duration.isEmpty ? "0:18" : duration)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        labeledField("Title", text: $noteTitle, placeholder: "Morning thought")
                        labeledField("Duration", text: $duration, placeholder: "0:18")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        VoiceNoteBlockView(
                            block: InputBlock(type: .voiceNote, text: noteTitle, duration: duration)
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
                    Button("Save") { onSave(noteTitle, duration) }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
        }
    }
}

#Preview {
    VoiceNoteEditorSheet(title: "New Voice Note", noteTitle: "Voice Note", duration: "0:18",
                         onCancel: {}, onSave: { _, _ in })
}
