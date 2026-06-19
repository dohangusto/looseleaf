import SwiftUI

/// Full-screen, native-feeling voice note recording / preview screen.
/// Dummy/static for now — no real audio capture.
struct VoiceNoteInputView: View {
    var subtitle: String = "Today, 09:41   00:01"
    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator.
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Top bar.
            HStack {
                circleButton("xmark", tint: .primary, action: onCancel)
                Spacer()
                circleButton("checkmark", tint: .white, background: .blue, action: onSave)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Title + subtitle.
            VStack(spacing: 6) {
                Text("New Voice Note")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            Spacer(minLength: 16)

            WaveformPreviewView()
                .padding(.horizontal, 20)

            // Timer.
            Text("00:00,80")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.top, 24)

            Spacer(minLength: 16)

            VoiceNotePlaybackControlsView()
                .padding(.bottom, 24)

            // Bottom controls.
            HStack {
                Button(action: {}) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                        .frame(width: 48, height: 48)
                        .background(Color(.systemGray6), in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {}) {
                    Text("RESUME")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6), in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                // Balance the transcript button on the left.
                Color.clear.frame(width: 48, height: 48)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func circleButton(_ systemName: String,
                              tint: Color,
                              background: Color = Color(.systemGray6),
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(background, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VoiceNoteInputView(onCancel: {}, onSave: {})
}
