import SwiftUI

/// Floating, native-styled attachment menu shown above the bottom toolbar.
struct AttachmentMenuView: View {
    var onTakePhoto: () -> Void
    var onChoosePhoto: () -> Void
    var onRecordAudio: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row("camera", "Take Photo or Video", action: onTakePhoto)
            Divider().padding(.leading, 52)
            row("photo.on.rectangle", "Choose Photo or Video", action: onChoosePhoto)
            Divider().padding(.leading, 52)
            row("mic", "Record Audio", action: onRecordAudio)
            Divider().padding(.leading, 52)
            row("xmark", "Cancel", role: .cancel, action: onCancel)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
    }

    private enum RowRole { case normal, cancel }

    private func row(_ icon: String,
                     _ label: String,
                     role: RowRole = .normal,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 24)
                Text(label)
                    .font(.body)
                Spacer()
            }
            .foregroundStyle(role == .cancel ? Color.red : Color.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AttachmentMenuView(onTakePhoto: {}, onChoosePhoto: {}, onRecordAudio: {}, onCancel: {})
        .padding()
}
