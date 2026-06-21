import SwiftUI

/// A highlighted, reflective quote block with a left accent line.
struct QuoteBlockView: View {
    @Environment(\.cardVisuals) private var visuals
    let block: InputBlock

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(visuals.accent.opacity(0.5))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: visuals.size(18), weight: .semibold))
                    .foregroundStyle(visuals.secondaryText)

                Text(block.text)
                    .font(.system(size: visuals.size(17), weight: .medium))
                    .foregroundStyle(visuals.primaryText)

                if !block.secondaryText.isEmpty {
                    Text(block.secondaryText)
                        .font(.system(size: visuals.size(13)))
                        .italic()
                        .foregroundStyle(visuals.secondaryText)
                }
            }

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    QuoteBlockView(
        block: InputBlock(type: .quote,
                          text: "Mulai dari dirimu sendiri.",
                          secondaryText: "Tidak ada yang berubah kalau tidak ada yang bergerak")
    )
    .padding()
}
