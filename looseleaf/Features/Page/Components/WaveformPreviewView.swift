import SwiftUI

/// Static, dummy waveform canvas with a centered yellow playhead.
struct WaveformPreviewView: View {
    /// Dummy normalized bar heights (0...1).
    private let bars: [CGFloat] = [
        0.2, 0.35, 0.5, 0.3, 0.65, 0.45, 0.8, 0.55, 0.9, 0.6,
        0.75, 0.4, 0.95, 0.7, 0.5, 0.85, 0.6, 0.3, 0.45, 0.25,
        0.4, 0.6, 0.35, 0.7, 0.5, 0.8, 0.45, 0.6, 0.3, 0.5
    ]

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6))

                // Red waveform bars.
                HStack(alignment: .center, spacing: 3) {
                    ForEach(bars.indices, id: \.self) { i in
                        Capsule()
                            .fill(Color.red.opacity(0.85))
                            .frame(width: 3, height: max(6, bars[i] * 120))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)

                // Centered yellow playhead with handles.
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 3)
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                }
            }
            .frame(height: 170)

            // Timeline labels.
            HStack {
                Text("00:00")
                Spacer()
                Text("00:01")
                Spacer()
                Text("00:02")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    WaveformPreviewView()
        .padding()
}
