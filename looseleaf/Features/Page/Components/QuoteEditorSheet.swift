import SwiftUI

/// Bottom sheet to create or edit a Quote block.
struct QuoteEditorSheet: View {
    let title: String
    @State private var quote: String
    @State private var context: String
    var onCancel: () -> Void
    var onSave: (_ quote: String, _ context: String) -> Void

    init(title: String,
         quote: String,
         context: String,
         onCancel: @escaping () -> Void,
         onSave: @escaping (String, String) -> Void) {
        self.title = title
        self._quote = State(initialValue: quote)
        self._context = State(initialValue: context)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        labeledField("Quote", text: $quote, placeholder: "Mulai dari dirimu sendiri.")
                        labeledField("Description / context", text: $context,
                                     placeholder: "Tidak ada yang berubah kalau tidak ada yang bergerak")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        QuoteBlockView(
                            block: InputBlock(type: .quote, text: quote, secondaryText: context)
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
                    Button("Save") { onSave(quote, context) }
                        .fontWeight(.semibold)
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
    QuoteEditorSheet(title: "Edit Quote",
                     quote: "Mulai dari dirimu sendiri.",
                     context: "Tidak ada yang berubah kalau tidak ada yang bergerak",
                     onCancel: {}, onSave: { _, _ in })
}
