import SwiftUI

/// App-level settings: appearance and data management.
struct SettingsView: View {
    @AppStorage("cardDarkModeEnabled") private var isDarkModeEnabled = false
    var onReset: () -> Void
    var onDone: () -> Void

    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: $isDarkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset sample data", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Replaces all notes with the original sample set.")
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone).fontWeight(.semibold)
                }
            }
            .alert("Reset sample data?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { onReset(); onDone() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will discard your changes and restore the sample notes.")
            }
        }
    }
}

#Preview {
    SettingsView(onReset: {}, onDone: {})
}
