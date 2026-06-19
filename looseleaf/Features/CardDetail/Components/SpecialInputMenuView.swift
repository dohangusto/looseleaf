import SwiftUI

/// Native-styled floating menu listing the available input types.
struct SpecialInputMenuView: View {
    @Binding var selectedType: InputBlockType
    var onSelect: (InputBlockType) -> Void

    private let order: [InputBlockType] = [
        .vocabulary, .quote, .expenses
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(order) { type in
                Button {
                    onSelect(type)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.system(size: 15))
                            .frame(width: 24)
                            .foregroundStyle(.blue)

                        Text(type.label)
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if type != order.last {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
    }
}

#Preview {
    SpecialInputMenuView(selectedType: .constant(.default)) { _ in }
        .padding()
}
