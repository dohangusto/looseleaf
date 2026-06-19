import SwiftUI

/// A compact voice-note attachment card embedded in the page, with a transcript
/// preview. Styled consistently with the other special blocks.
struct VoiceNoteBlockView: View {
    let block: InputBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.blue)

                Text(block.text.isEmpty ? "Voice Note" : block.text)
                    .font(.body)
                    .fontWeight(.semibold)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                    Text("Play")
                        .font(.subheadline)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Transcript")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Text(block.transcript.isEmpty
                     ? "No transcript yet."
                     : block.transcript)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
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
