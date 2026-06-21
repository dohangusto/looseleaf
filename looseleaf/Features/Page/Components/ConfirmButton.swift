import SwiftUI

extension Color {
    /// Warm golden "Citrine" accent used for confirmation buttons.
    static let citrine = Color(red: 0.89, green: 0.72, blue: 0.23)
}

/// A circular checkmark confirmation button with a Citrine background.
/// Used in place of a plain "Done"/"Save" text button in sheets.
struct ConfirmButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.citrine)
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
            }
            .frame(width: 34, height: 34)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Confirm")
    }
}

#Preview {
    ConfirmButton(action: {})
        .padding()
}
