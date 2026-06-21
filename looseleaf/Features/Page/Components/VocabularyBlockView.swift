import SwiftUI

/// A compact dictionary-entry block embedded in the note.
struct VocabularyBlockView: View {
    @Environment(\.cardVisuals) private var visuals
    let block: InputBlock

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: visuals.size(16), weight: .semibold))
                .foregroundStyle(visuals.accent)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(block.text)
                    .font(.system(size: visuals.size(17), weight: .semibold))
                    .foregroundStyle(visuals.accent)

                Text(block.secondaryText)
                    .font(.system(size: visuals.size(15)))
                    .italic()
                    .foregroundStyle(visuals.secondaryText)

                if !block.language.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: visuals.size(10)))
                        Text(block.language)
                            .font(.system(size: visuals.size(11), weight: .medium))
                    }
                    .foregroundStyle(visuals.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(visuals.accent.opacity(0.12), in: Capsule())
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(visuals.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(visuals.borderColor, lineWidth: visuals.borderWidth)
        )
    }
}

#Preview {
    VocabularyBlockView(
        block: InputBlock(type: .vocabulary,
                          text: "collateral —",
                          secondaryText: "jaminan atau agunan",
                          language: "English")
    )
    .padding()
}
