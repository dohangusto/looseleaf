import SwiftUI

/// Floating native-style accessibility panel: dark mode, font size, contrast.
struct AppearanceMenuView: View {
    @Binding var isDarkModeEnabled: Bool
    @Binding var fontScale: CGFloat
    @Binding var contrastScale: CGFloat
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Dark Mode toggle
            HStack(spacing: 12) {
                icon("moon.fill")
                Text("Dark Mode")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $isDarkModeEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider().padding(.leading, 52)

            // Font Size
            HStack(spacing: 12) {
                icon("textformat.size")
                Slider(value: $fontScale, in: 0.85...1.35)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider().padding(.leading, 52)

            // Contrast
            HStack(spacing: 12) {
                icon("circle.righthalf.filled")
                Slider(value: $contrastScale, in: 0.8...1.3)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider().padding(.leading, 52)

            // Cancel
            Button(action: onCancel) {
                HStack(spacing: 12) {
                    icon("xmark", tint: .red)
                    Text("Cancel")
                        .font(.body)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
    }

    private func icon(_ name: String, tint: Color = .primary) -> some View {
        Image(systemName: name)
            .font(.system(size: 16))
            .foregroundStyle(tint)
            .frame(width: 24)
    }
}

#Preview {
    AppearanceMenuView(
        isDarkModeEnabled: .constant(false),
        fontScale: .constant(1.0),
        contrastScale: .constant(1.0),
        onCancel: {}
    )
    .padding()
}
