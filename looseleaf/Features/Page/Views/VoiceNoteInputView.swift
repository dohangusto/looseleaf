import SwiftUI

/// Full-screen, native-feeling voice note screen with two modes:
/// - `.create`: recording UI (editable title + record button + playback + waveform).
/// - `.edit`: full detail (title, date, waveform, recording time, transcript + copy, playback).
/// Dummy/static for now — no real audio capture.
struct VoiceNoteInputView: View {
    enum Mode { case create, edit }

    let mode: Mode
    let createdAt: String
    let durationDetail: String
    let transcript: String
    var onCancel: () -> Void
    /// Returns the final (possibly edited) title.
    var onSave: (_ title: String) -> Void

    @State private var title: String
    @State private var isRecording = false
    @State private var didCopy = false
    @FocusState private var titleFocused: Bool

    init(mode: Mode,
         initialTitle: String,
         createdAt: String = "",
         durationDetail: String = "00:00",
         transcript: String = "",
         onCancel: @escaping () -> Void,
         onSave: @escaping (String) -> Void) {
        self.mode = mode
        self.createdAt = createdAt
        self.durationDetail = durationDetail
        self.transcript = transcript
        self.onCancel = onCancel
        self.onSave = onSave
        _title = State(initialValue: initialTitle)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator.
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Top bar — checkmark confirms in both modes.
            HStack {
                circleButton("xmark", tint: .primary, action: onCancel)
                Spacer()
                circleButton("checkmark", tint: .black, background: .citrine) {
                    onSave(title.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : title)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Editable title — tap shows the keyboard.
                    TextField("Title", text: $title)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .focused($titleFocused)
                        .submitLabel(.done)
                        .padding(.top, 8)

                    if !createdAt.isEmpty || mode == .edit {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    WaveformPreviewView()
                        .padding(.top, 4)

                    // Recording time detail.
                    Text(mode == .edit ? bigTime(durationDetail) : "00:00,00")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    VoiceNotePlaybackControlsView()

                    if mode == .edit {
                        transcriptSection
                    } else {
                        recordButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private var subtitle: String {
        if createdAt.isEmpty { return durationDetail }
        return "\(createdAt)  ·  \(durationDetail)"
    }

    // MARK: - Edit: transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Transcript")
                    .font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = transcript
                    withAnimation { didCopy = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { didCopy = false }
                    }
                } label: {
                    Label(didCopy ? "Copied" : "Copy",
                          systemImage: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            Text(transcript.isEmpty ? "No transcript available." : transcript)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
        }
        .padding(.top, 8)
    }

    // MARK: - Create: record button

    private var recordButton: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isRecording.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color(.systemGray4), lineWidth: 4)
                        .frame(width: 76, height: 76)
                    RoundedRectangle(cornerRadius: isRecording ? 8 : 32, style: .continuous)
                        .fill(Color.red)
                        .frame(width: isRecording ? 32 : 60, height: isRecording ? 32 : 60)
                }
            }
            .buttonStyle(.plain)

            Text(isRecording ? "Recording…" : "Tap to record")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    /// "00:12" → "00:12,00" for the big rounded timer styling.
    private func bigTime(_ value: String) -> String {
        value.contains(",") ? value : "\(value),00"
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

#Preview("Create") {
    VoiceNoteInputView(mode: .create, initialTitle: "New Recording 1",
                       onCancel: {}, onSave: { _ in })
}

#Preview("Edit") {
    VoiceNoteInputView(
        mode: .edit,
        initialTitle: "Design feedback dari Kak Keke",
        createdAt: "22 Jun 2026, 09:41",
        durationDetail: "00:18",
        transcript: "Jadi gini, menurut aku komponen kartunya itu mending pakai auto layout dulu ya, biar pas di-resize nggak berantakan.",
        onCancel: {}, onSave: { _ in }
    )
}
