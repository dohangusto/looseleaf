import SwiftUI

/// A compact voice-note attachment card embedded in the page, with a transcript
/// preview. Styled consistently with the other special blocks.
struct VoiceNoteBlockView: View {
    @Environment(\.cardVisuals) private var visuals
    let block: InputBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.system(size: visuals.size(15)))
                    .foregroundStyle(visuals.accent)

                Text(block.text.isEmpty ? "Voice Note" : block.text)
                    .font(.system(size: visuals.size(17), weight: .semibold))
                    .foregroundStyle(visuals.primaryText)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: visuals.size(11)))
                    Text("Play")
                        .font(.system(size: visuals.size(15)))
                }
                .foregroundStyle(visuals.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(visuals.accent.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Transcript")
                    .font(.system(size: visuals.size(12), weight: .bold))
                    .foregroundStyle(visuals.secondaryText)

                Text(block.transcript.isEmpty
                     ? "No transcript yet."
                     : block.transcript)
                    .font(.system(size: visuals.size(12)))
                    .italic()
                    .foregroundStyle(visuals.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
    VoiceNoteBlockView(
        block: InputBlock(type: .voiceNote,
                          text: "Design Feedback",
                          transcript: "Oke, kayaknya better kamu ubah komponen ini pake autolayout dulu...")
    )
    .padding()
}
