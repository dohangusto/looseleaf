import SwiftUI

struct JournalCardView: View {
    let entry: JournalEntry

    private let cardRadius: CGFloat = 16
    private let cardHeight: CGFloat = 190

    // One sheet per extra page, capped at 3 sheets behind the card.
    private var stackCount: Int {
        min(max(entry.pageCount - 1, 0), 3)
    }

    var body: some View {
        ZStack {
            // Stacked pages behind the main card, drawn back-to-front.
            ForEach(Array((1...max(stackCount, 1)).reversed()), id: \.self) { level in
                if level <= stackCount {
                    RoundedRectangle(cornerRadius: cardRadius)
                        .fill(Color(white: 0.86 - Double(level) * 0.04))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
                        .rotationEffect(.degrees(Double(level) * 2.5), anchor: .bottom)
                        .offset(y: CGFloat(level) * 9)
                }
            }

            // Main card content
            if entry.imageName != nil {
                imageCard
            } else {
                textCard
            }
        }
        .frame(height: cardHeight)
        // Constant footprint for every card so the grid rows stay aligned,
        // regardless of whether the stacked-page sheets peek out below.
        .padding(.bottom, 32)
    }

    // MARK: - Image Card (background image, no body text)

    private var imageCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            dateBadge(light: true)

            if let level = entry.level {
                levelBadge(level: level, light: true)
            }

            Spacer(minLength: 0)

            Text(entry.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: cardHeight)
        .background {
            ZStack {
                Image(entry.imageName!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

                LinearGradient(
                    colors: [.black.opacity(0.25), .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        // Broad, soft depth shadow so the card clearly lifts off the background.
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 16)
    }

    // MARK: - Text Card (white background, with body text)

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            dateBadge(light: false)

            if let level = entry.level {
                levelBadge(level: level, light: false)
            }

            Text(entry.title)
                .font(.headline)
                .fontWeight(.bold)

            if !entry.caption.isEmpty {
                Text(entry.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: cardHeight, alignment: .top)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        // Broad, soft depth shadow so the card clearly lifts off the background.
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 16)
    }

    // MARK: - Badges

    private func dateBadge(light: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text(entry.isToday ? "Today" : entry.formattedDate)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(light ? .white.opacity(0.9) : .secondary)
    }

    private func levelBadge(level: JournalLevel, light: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.system(size: 10))
            Text(level.rawValue)
                .font(.caption2)
                .italic()
        }
        .foregroundStyle(light ? .white.opacity(0.9) : .secondary)
    }
}
