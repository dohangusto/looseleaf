import SwiftUI

/// A small panel for choosing which block types are shown on the page.
/// Presented as a sheet so toggling stays open until the user is done.
struct ShowByTypeSheet: View {
    @Binding var visibleTypes: Set<InputBlockType>
    var onDone: () -> Void
    var onMerge: () -> Void

    /// Offer merging only when a meaningful subset (1–4) is selected.
    private var canMerge: Bool {
        (1..<5).contains(visibleTypes.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(InputBlockType.selectableTypes) { type in
                        Toggle(isOn: binding(for: type)) {
                            Label(type.label, systemImage: type.icon)
                        }
                    }
                }
            }
            .navigationTitle("Show by Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmButton(action: onDone)
                }
            }
            // Actions pinned to the bottom so they're always visible.
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if canMerge {
                        Button(action: onMerge) {
                            Label("Merge in One Page", systemImage: "square.stack.3d.down.forward")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button {
                        visibleTypes = Set(InputBlockType.selectableTypes)
                    } label: {
                        Label("Show All", systemImage: "square.grid.2x2")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(.ultraThinMaterial)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func binding(for type: InputBlockType) -> Binding<Bool> {
        Binding(
            get: { visibleTypes.contains(type) },
            set: { isOn in
                if isOn { visibleTypes.insert(type) } else { visibleTypes.remove(type) }
            }
        )
    }
}

#Preview {
    ShowByTypeSheet(visibleTypes: .constant([.image, .voiceNote]), onDone: {}, onMerge: {})
}
