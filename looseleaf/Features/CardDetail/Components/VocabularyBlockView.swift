import SwiftUI

/// A compact dictionary-entry block embedded in the note.
struct VocabularyBlockView: View {
    let block: InputBlock

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(block.text)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)

                Text(block.secondaryText)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5)
        )
    }
}

#Preview {
    VocabularyBlockView(
        block: InputBlock(type: .vocabulary,
                          text: "Komorebi —",
                          secondaryText: "sunlight filtering through trees")
    )
    .padding()
}
