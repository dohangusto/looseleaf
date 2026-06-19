import SwiftUI

struct FeaturedCardView: View {
    let entry: JournalEntry

    private let cardRadius: CGFloat = 16

    // One sheet per extra page, capped at 3 sheets behind the card.
    private var stackCount: Int {
        min(max(entry.pageCount - 1, 0), 3)
    }

    var body: some View {
        ZStack {
            // Stacked pages behind the card, drawn back-to-front.
            ForEach(Array((1...max(stackCount, 1)).reversed()), id: \.self) { level in
                if level <= stackCount {
                    RoundedRectangle(cornerRadius: cardRadius)
                        .fill(Color(white: 0.86 - Double(level) * 0.04))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
                        .rotationEffect(.degrees(Double(level) * 1.6), anchor: .bottom)
                        .offset(y: CGFloat(level) * 9)
                }
            }

            cardContent
        }
        .padding(.bottom, 32)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top row: pin logo + date
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "pin.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(45))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.isToday ? "Today" : entry.formattedDate)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(entry.shortFormattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            // Bottom row: title + body column alongside the image
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if !entry.caption.isEmpty {
                        Text(entry.caption)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 0)

                if let imageName = entry.imageName {
                    Color.clear
                        .frame(width: 110, height: 90)
                        .overlay {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        // Broad, soft depth shadow so the card clearly lifts off the background.
        .shadow(color: .black.opacity(0.16), radius: 28, x: 0, y: 18)
    }
}
