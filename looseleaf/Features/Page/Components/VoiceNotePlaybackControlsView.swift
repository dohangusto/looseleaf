import SwiftUI

/// Dummy playback controls: rewind 15s, play, forward 15s.
struct VoiceNotePlaybackControlsView: View {
    var onRewind: () -> Void = {}
    var onPlay: () -> Void = {}
    var onForward: () -> Void = {}

    var body: some View {
        HStack(spacing: 44) {
            Button(action: onRewind) {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 26))
                    .foregroundStyle(.primary)
            }

            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.primary)
                    .frame(width: 72, height: 72)
                    .background(Color(.systemGray6), in: Circle())
            }

            Button(action: onForward) {
                Image(systemName: "goforward.15")
                    .font(.system(size: 26))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VoiceNotePlaybackControlsView()
}
