import SwiftUI

/// A highlighted, reflective quote block with a left accent line.
struct QuoteBlockView: View {
    let block: InputBlock

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue.opacity(0.5))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(block.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if !block.secondaryText.isEmpty {
                    Text(block.secondaryText)
                        .font(.footnote)
                        .italic()
                        .foregroundStyle(.secondary)
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
