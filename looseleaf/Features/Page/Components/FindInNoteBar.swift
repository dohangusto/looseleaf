import SwiftUI

/// Browser-style search bar for finding content within a page, with
/// previous/next navigation across matches.
struct FindInNoteBar: View {
    @Binding var query: String
    let matchCount: Int
    let currentIndex: Int
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onClose: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Find in note", text: $query)
                    .focused($focused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Text(matchCount == 0 ? (query.isEmpty ? "" : "0/0") : "\(currentIndex + 1)/\(matchCount)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill), in: Capsule())

            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
            }
            .disabled(matchCount == 0)

            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .disabled(matchCount == 0)

            Button("Done", action: onClose)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .onAppear { focused = true }
    }
}

#Preview {
    FindInNoteBar(query: .constant("kopi"), matchCount: 3, currentIndex: 0,
                  onPrevious: {}, onNext: {}, onClose: {})
}
