import SwiftUI

/// A lightweight, native-feeling audio card.
struct VoiceNoteBlockView: View {
    let block: InputBlock

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.text.isEmpty ? "Voice Note" : block.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(block.duration.isEmpty ? "0:12" : block.duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}

#Preview {
    VoiceNoteBlockView(
        block: InputBlock(type: .voiceNote, text: "Morning thought", duration: "0:24")
    )
    .padding()
}
